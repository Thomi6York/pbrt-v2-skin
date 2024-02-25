// materials/uv_pass.h

#ifndef PBRT_MATERIALS_UV_PASS_H
#define PBRT_MATERIALS_UV_PASS_H

#include "pbrt.h"
#include "material.h"
#include "spectrum.h"
#include "reflection.h"
#include "paramset.h"
#include "texture.h"
#include "textures/uv.h"

class UVPassMaterial : public Material {
public:
    UVPassMaterial(Reference<Texture<Spectrum>> uvTexture);

    BSDF *GetBSDF(const DifferentialGeometry &dgGeom, const DifferentialGeometry &dgShading, MemoryArena &arena) const override;

private:
    Reference<Texture<Spectrum>> uvTexture;
};

UVPassMaterial *CreateUVPassMaterial(const Transform &xform, const TextureParams &mp, const DifferentialGeometry& dgGeom);

#endif // PBRT_MATERIALS_UV_PASS_H
