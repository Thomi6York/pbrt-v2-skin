#if defined(_MSC_VER)
#pragma once
#endif

#ifndef PBRT_FILM_XYZ_IMAGE_H
#define PBRT_FILM_XYZ_IMAGE_H

// film/image.h*
#include "pbrt.h"
#include "film.h"
#include "sampler.h"
#include "filter.h"
#include "paramset.h"

// const bool debugMode = false;    //Andy added this flag for debugging

// XYZFilm Declarations
class XYZFilm : public Film {
public:
    // XYZFilm Public Methods
    XYZFilm(int xres, int yres, Filter *filt, const float crop[4],
              const string &filename, bool openWindow);
    ~XYZFilm() {
        delete pixels;
        delete filter;
        delete[] filterTable;
    }
    void AddSample(const CameraSample &sample, const Spectrum &L, const Ray &currentRay);
    void Splat(const CameraSample &sample, const Spectrum &L);
    void GetSampleExtent(int *xstart, int *xend, int *ystart, int *yend) const;
    void GetPixelExtent(int *xstart, int *xend, int *ystart, int *yend) const;
    void WriteImage(float splatScale);
    void UpdateDisplay(int x0, int y0, int x1, int y1, float splatScale);
private:

    // XYZFilm Private Data
    Filter *filter;
    float cropWindow[4];
    string filename;
    int xPixelStart, yPixelStart, xPixelCount, yPixelCount;
    //Andy: modified this to allow for multispectral
   struct Pixel {
        Pixel() {
            for (int i = 0; i < 3; ++i) Lxyz[i] = splatXYZ[i] = 0.f;
            weightSum = 0.f;
        }
        float Lxyz[3];
        float weightSum;
        float splatXYZ[3];
        float pad;
    };
    BlockedArray<Pixel> *pixels;
    float *filterTable;

};

//XYZFilm *CreateXYZFilm(const ParamSet &params, Filter *filter, Camera * baseCamera);
XYZFilm *CreateXYZFilm(const ParamSet &params, Filter *filter);

#endif // PBRT_FILM_XYZ_IMAGE_H
