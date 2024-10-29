
// film/XYZfilm.cpp*
#include <sstream>
#include <iostream>
#include <fstream>
#include "stdafx.h"
#include "film/XYZfilm.h"
#include "spectrum.h"
#include "parallel.h"
#include "imageio.h"
#include "floatfile.h"
//#include "cameras/realisticDiffraction.h"
#include <typeinfo>
#include <math.h>

// XYZFilm Method Definitions
XYZFilm::XYZFilm(int xres, int yres, Filter *filt, const float crop[4],
                 const string &fn, bool openWindow)
    : Film(xres, yres) {
    filter = filt;
    memcpy(cropWindow, crop, 4 * sizeof(float));
    filename = fn;
    // Compute film image extent
    xPixelStart = Ceil2Int(xResolution * cropWindow[0]);
    xPixelCount = max(1, Ceil2Int(xResolution * cropWindow[1]) - xPixelStart);
    yPixelStart = Ceil2Int(yResolution * cropWindow[2]);
    yPixelCount = max(1, Ceil2Int(yResolution * cropWindow[3]) - yPixelStart);

    // Allocate film image storage
    pixels = new BlockedArray<Pixel>(xPixelCount, yPixelCount);

    // Precompute filter weight table
#define FILTER_TABLE_SIZE 16
    filterTable = new float[FILTER_TABLE_SIZE * FILTER_TABLE_SIZE];
    float *ftp = filterTable;
    for (int y = 0; y < FILTER_TABLE_SIZE; ++y) {
        float fy = ((float)y + .5f) *
                   filter->yWidth / FILTER_TABLE_SIZE;
        for (int x = 0; x < FILTER_TABLE_SIZE; ++x) {
            float fx = ((float)x + .5f) *
                       filter->xWidth / FILTER_TABLE_SIZE;
            *ftp++ = filter->Evaluate(fx, fy);
        }
    }
}

void XYZFilm::AddSample(const CameraSample &sample,
                        const Spectrum &L, const Ray &currentRay) {
    // Compute sample's raster extent
    float dimageX = sample.imageX - 0.5f;
    float dimageY = sample.imageY - 0.5f;
    int x0 = Ceil2Int(dimageX - filter->xWidth);
    int x1 = Floor2Int(dimageX + filter->xWidth);
    int y0 = Ceil2Int(dimageY - filter->yWidth);
    int y1 = Floor2Int(dimageY + filter->yWidth);
    x0 = max(x0, xPixelStart);
    x1 = min(x1, xPixelStart + xPixelCount - 1);
    y0 = max(y0, yPixelStart);
    y1 = min(y1, yPixelStart + yPixelCount - 1);
    if ((x1 - x0) < 0 || (y1 - y0) < 0) {
        PBRT_SAMPLE_OUTSIDE_IMAGE_EXTENT(const_cast<CameraSample *>(&sample));
        return;
    }

    // Loop over filter support and add sample to pixel arrays
    float xyz[3];
    L.ToXYZ(xyz);

    // Precompute $x$ and $y$ filter table offsets
    int *ifx = ALLOCA(int, x1 - x0 + 1);
    for (int x = x0; x <= x1; ++x) {
        float fx = fabsf((x - dimageX) *
                         filter->invXWidth * FILTER_TABLE_SIZE);
        ifx[x - x0] = min(Floor2Int(fx), FILTER_TABLE_SIZE - 1);
    }
    int *ify = ALLOCA(int, y1 - y0 + 1);
    for (int y = y0; y <= y1; ++y) {
        float fy = fabsf((y - dimageY) *
                         filter->invYWidth * FILTER_TABLE_SIZE);
        ify[y - y0] = min(Floor2Int(fy), FILTER_TABLE_SIZE - 1);
    }
    bool syncNeeded = (filter->xWidth > 0.5f || filter->yWidth > 0.5f);
    for (int y = y0; y <= y1; ++y) {
        for (int x = x0; x <= x1; ++x) {
            // Evaluate filter value at $(x,y)$ pixel
            int offset = ify[y - y0] * FILTER_TABLE_SIZE + ifx[x - x0];
            float filterWt = filterTable[offset];

            // Update pixel values with filtered sample contribution
            Pixel &pixel = (*pixels)(x - xPixelStart, y - yPixelStart);
            if (!syncNeeded) {
                pixel.Lxyz[0] += filterWt * xyz[0];
                pixel.Lxyz[1] += filterWt * xyz[1];
                pixel.Lxyz[2] += filterWt * xyz[2];
                pixel.weightSum += filterWt;
            } else {
                // Safely update _Lxyz_ and _weightSum_ even with concurrency
                AtomicAdd(&pixel.Lxyz[0], filterWt * xyz[0]);
                AtomicAdd(&pixel.Lxyz[1], filterWt * xyz[1]);
                AtomicAdd(&pixel.Lxyz[2], filterWt * xyz[2]);
                AtomicAdd(&pixel.weightSum, filterWt);
            }
        }
    }
}

void XYZFilm::Splat(const CameraSample &sample, const Spectrum &L) {
    if (L.HasNaNs()) {
        Warning("XYZFilm ignoring splatted spectrum with NaN values");
        return;
    }

    float xyz[3];
    L.ToXYZ(xyz);

    int x = Floor2Int(sample.imageX), y = Floor2Int(sample.imageY);
    if (x < xPixelStart || x - xPixelStart >= xPixelCount ||
        y < yPixelStart || y - yPixelStart >= yPixelCount)
        return;
    Pixel &pixel = (*pixels)(x - xPixelStart, y - yPixelStart);
    AtomicAdd(&pixel.splatXYZ[0], xyz[0]);
    AtomicAdd(&pixel.splatXYZ[1], xyz[1]);
    AtomicAdd(&pixel.splatXYZ[2], xyz[2]);
}

void XYZFilm::GetSampleExtent(int *xstart, int *xend,
                              int *ystart, int *yend) const {
    *xstart = Floor2Int(xPixelStart + 0.5f - filter->xWidth);
    *xend = Floor2Int(xPixelStart + 0.5f + xPixelCount +
                      filter->xWidth);

    *ystart = Floor2Int(yPixelStart + 0.5f - filter->yWidth);
    *yend = Floor2Int(yPixelStart + 0.5f + yPixelCount +
                      filter->yWidth);
}

void XYZFilm::GetPixelExtent(int *xstart, int *xend,
                             int *ystart, int *yend) const {
    *xstart = xPixelStart;
    *xend = xPixelStart + xPixelCount;
    *ystart = yPixelStart;
    *yend = yPixelStart + yPixelCount;
}

void XYZFilm::WriteImage(float splatScale) {
    // Convert image to XYZ and compute final pixel values
    int nPix = xPixelCount * yPixelCount;
    float *xyz = new float[3 * nPix];

    int offset = 0;
    for (int y = 0; y < yPixelCount; ++y) {
        for (int x = 0; x < xPixelCount; ++x) {
            //Convert spectral format XYZ to pixel XYZ
            xyz[3 * offset] = (*pixels)(x, y).Lxyz[0];
            xyz[3 * offset + 1] = (*pixels)(x, y).Lxyz[1];
            xyz[3 * offset + 2] = (*pixels)(x, y).Lxyz[2];

            // Normalize pixel with weight sum
            float weightSum = (*pixels)(x, y).weightSum;
            if (weightSum != 0.f) {
                float invWt = 1.f / weightSum;
                xyz[3 * offset] = max(0.f, xyz[3 * offset] * invWt);
                xyz[3 * offset + 1] = max(0.f, xyz[3 * offset + 1] * invWt);
                xyz[3 * offset + 2] = max(0.f, xyz[3 * offset + 2] * invWt);
            }

            // Add splat value at pixel
            xyz[3 * offset] += splatScale * (*pixels)(x, y).splatXYZ[0];
            xyz[3 * offset + 1] += splatScale * (*pixels)(x, y).splatXYZ[1];
            xyz[3 * offset + 2] += splatScale * (*pixels)(x, y).splatXYZ[2];

            ++offset;
        }
    }
    // Write image to EXR file (XYZ output)
    string xyzFilename = filename.substr(0, filename.find_last_of('.')) + "_xyz.exr";
    ::WriteImage(xyzFilename, xyz, NULL, xPixelCount, yPixelCount,
                 xResolution, yResolution, xPixelStart, yPixelStart);
    std::cout << "Wrote image to " << xyzFilename << std::endl;
    // Convert XYZ to RGB
    float *rgb = new float[3 * nPix];
    for (int i = 0; i < nPix; ++i) {
        XYZToRGB(&xyz[3 * i], &rgb[3 * i]);
    }

    // Write image to EXR file (RGB output)
    string rgbFilename = filename.substr(0, filename.find_last_of('.')) + "_rgb.exr";
    ::WriteImage(rgbFilename, rgb, NULL, xPixelCount, yPixelCount,
                 xResolution, yResolution, xPixelStart, yPixelStart);
    std::cout << "Wrote image to " << rgbFilename << std::endl;

    // Release temporary RGB image memory
    delete[] rgb;

    // Release temporary image memory
    delete[] xyz;
}

void XYZFilm::UpdateDisplay(int x0, int y0, int x1, int y1,
                            float splatScale) {
    // No display update needed
}

XYZFilm *CreateXYZFilm(const ParamSet &params, Filter *filter) {
    string filename = params.FindOneString("filename", PbrtOptions.imageFile);
    if (filename == "")
#ifdef PBRT_HAS_OPENEXR
        filename = "pbrt.exr";
#else
        filename = "pbrt.tga";
#endif

    int xres = params.FindOneInt("xresolution", 640);
    int yres = params.FindOneInt("yresolution", 480);

    if (PbrtOptions.quickRender) xres = max(1, xres / 4);
    if (PbrtOptions.quickRender) yres = max(1, yres / 4);
    bool openwin = params.FindOneBool("display", false);
    float crop[4] = {0, 1, 0, 1};
    int cwi;
    const float *cr = params.FindFloat("cropwindow", &cwi);
    if (cr && cwi == 4) {
        crop[0] = Clamp(min(cr[0], cr[1]), 0., 1.);
        crop[1] = Clamp(max(cr[0], cr[1]), 0., 1.);
        crop[2] = Clamp(min(cr[2], cr[3]), 0., 1.);
        crop[3] = Clamp(max(cr[2], cr[3]), 0., 1.);
    }

    return new XYZFilm(xres, yres, filter, crop, filename, openwin);
}

