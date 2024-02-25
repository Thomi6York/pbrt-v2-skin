// materials/uv_pass.cpp

#include "stdafx.h"
#include "UVpass.h"
#include "paramset.h"
#include "spectrum.h"
#include "reflection.h"
#include "paramset.h"
#include "texture.h"
#include "textures/uv.h"// this is important -- does most of the UV pass

// UVPassMaterial Constructor
UVPassMaterial::UVPassMaterial(Reference<Texture<Spectrum>> uvTextureMap)
    : uvTexture(uvTextureMap) {}

// UVPassMaterial GetBSDF Method
BSDF *UVPassMaterial::GetBSDF(const DifferentialGeometry &dgGeom, const DifferentialGeometry &dgShading, MemoryArena &arena) const {
    // Use uvTexture to get UV coordinates
    Spectrum uv = uvTexture->Evaluate(dgShading);

    // Construct a BSDF with UV coordinates
    BSDF *bsdf = BSDF_ALLOC(arena, BSDF)(dgGeom, dgShading.nn, 1.0f);

    // Set UV coordinates as the color of the surface
    bsdf->Add(BSDF_ALLOC(arena, Lambertian)(uv));

    return bsdf;
}

// CreateUVPassMaterial Function
UVPassMaterial *CreateUVPassMaterial(const Transform &xform, const TextureParams &mp, const DifferentialGeometry& dgGeom) {
    // Initialize 2D texture mapping from the differential geometry
    TextureMapping2D* map = new UVMapping2D(dgGeom.u, dgGeom.v);
    
    // Create UV texture
    UVTexture* uvTexture = new UVTexture(map);

    // Create UV pass material
    return new UVPassMaterial(uvTexture);
}

