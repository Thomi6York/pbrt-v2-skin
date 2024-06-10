
/*
    pbrt source code Copyright(c) 1998-2012 Matt Pharr and Greg Humphreys.

    This file is part of pbrt.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:

    - Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
    IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */


// core/material.cpp*
#include "stdafx.h"
#include "material.h"
#include "primitive.h"
#include "texture.h"
#include "spectrum.h"
#include "reflection.h"

// Material Method Definitions
Material::~Material() {
}

uint32_t Material::nextMaterialId = 0;

void Material::Bump(const Reference<Texture<float> > &d,
                    const DifferentialGeometry &dgGeom,
                    const DifferentialGeometry &dgs,
                    DifferentialGeometry *dgBump) {
    // Compute offset positions and evaluate displacement texture
    DifferentialGeometry dgEval = dgs;

    // Shift _dgEval_ _du_ in the $u$ direction
    float du = /*.5f * */(fabsf(dgs.dudx) + fabsf(dgs.dudy));
    if (du == 0.f) du = .01f;
    dgEval.p = dgs.p + du * dgs.dpdu;
    dgEval.u = dgs.u + du;
    dgEval.nn = Normalize((Normal)Cross(dgs.dpdu, dgs.dpdv) +
                          du * dgs.dndu);
    float upDisplace = d->Evaluate(dgEval);

    // Shift _dgEval_ _dv_ in the $v$ direction
    float dv = /*.5f * */(fabsf(dgs.dvdx) + fabsf(dgs.dvdy));
    if (dv == 0.f) dv = .01f;
    dgEval.p = dgs.p + dv * dgs.dpdv;
    dgEval.u = dgs.u;
    dgEval.v = dgs.v + dv;
    dgEval.nn = Normalize((Normal)Cross(dgs.dpdu, dgs.dpdv) +
                          dv * dgs.dndv);
    float vpDisplace = d->Evaluate(dgEval);
    float displace = d->Evaluate(dgs);

    // Shift _dgEval_ _du_ in the $-u$ direction
    du = -du;
    dgEval.p = dgs.p + du * dgs.dpdu;
    dgEval.u = dgs.u + du;
    dgEval.nn = Normalize((Normal)Cross(dgs.dpdu, dgs.dpdv) +
                          du * dgs.dndu);
    float unDisplace = d->Evaluate(dgEval);

    // Shift _dgEval_ _dv_ in the $-v$ direction
	dv = -dv;
    dgEval.p = dgs.p + dv * dgs.dpdv;
    dgEval.u = dgs.u;
    dgEval.v = dgs.v + dv;
    dgEval.nn = Normalize((Normal)Cross(dgs.dpdu, dgs.dpdv) +
                          dv * dgs.dndv);
    float vnDisplace = d->Evaluate(dgEval);
    //float displace = d->Evaluate(dgs);

    // Compute bump-mapped differential geometry
    *dgBump = dgs;
    dgBump->dpdu = dgs.dpdu + (upDisplace - unDisplace) / (2 * du) * Vector(dgs.nn) +
                   displace * Vector(dgs.dndu);
    dgBump->dpdv = dgs.dpdv + (vpDisplace - vnDisplace) / (2 * dv) * Vector(dgs.nn) +
                   displace * Vector(dgs.dndv);
    dgBump->nn = Normal(Normalize(Cross(dgBump->dpdu, dgBump->dpdv)));
    if (dgs.shape->ReverseOrientation ^ dgs.shape->TransformSwapsHandedness)
        dgBump->nn *= -1.f;

    // Orient shading normal to match geometric normal
    dgBump->nn = Faceforward(dgBump->nn, dgGeom.nn);
}

// this is from the imperial code -- lets make it make more sense though
void Material::Norm_From_Spectrum(const Reference<Texture<Spectrum> > &d,
	const DifferentialGeometry &dgGeom,
	const DifferentialGeometry &dgs,
	DifferentialGeometry *dgBump) {
	// Compute offset positions and evaluate displacement texture
	DifferentialGeometry dgEval = dgs;

	Spectrum bump_spectrum = d->Evaluate(dgs);
	float* x_val_normal = bump_spectrum.nextSample(0);
	*x_val_normal = ((*x_val_normal * 2) - 1);

	float* y_val_normal = bump_spectrum.nextSample(1);
	*y_val_normal = ((*y_val_normal * 2) - 1);

	float* z_val_normal = bump_spectrum.nextSample(2);
	*z_val_normal = ((*z_val_normal * 2) - 1);

	if (*x_val_normal == 0) 
		{ *x_val_normal -= 0.0000001f; }
	if (*y_val_normal == 0) 
		{ *y_val_normal -= 0.0000001f; }
	if (*z_val_normal == 0) 
		{ *z_val_normal -= 0.0000001f; }

	Vector normal_from_texture = Vector(*x_val_normal, *y_val_normal, *z_val_normal);


	// Shift _dgEval_ _du_ in the $u$ direction
	float du = .5f * (fabsf(dgs.dudx) + fabsf(dgs.dudy));
	if (du == 0.f) du = .01f;
	dgEval.p = dgs.p + du * dgs.dpdu;
	dgEval.u = dgs.u + du;
	dgEval.nn = Normalize((Normal)Cross(dgs.dpdu, dgs.dpdv) +
		du * dgs.dndu);

	// Shift _dgEval_ _dv_ in the $v$ direction
	float dv = .5f * (fabsf(dgs.dvdx) + fabsf(dgs.dvdy));
	if (dv == 0.f) dv = .01f;
	dgEval.p = dgs.p + dv * dgs.dpdv;
	dgEval.u = dgs.u;
	dgEval.v = dgs.v + dv;
	dgEval.nn = Normalize((Normal)Cross(dgs.dpdu, dgs.dpdv) +
		dv * dgs.dndv);

  // all displacements are set to zero because we aren't bump mapping
  float uDisplace = 0.0f;
	float vDisplace = 0.0f;
	float displace = 0.0f;

	// Copy input shading geometry since we ignore displacements
	*dgBump = dgs;
	dgBump->nn = Normal(Normalize(normal_from_texture));
	
	//dgBump->nn = dgs.nn;

	if (dgs.shape->ReverseOrientation ^ dgs.shape->TransformSwapsHandedness)
		dgBump->nn *= -1.f;

	// Orient shading normal to match geometric normal
	dgBump->nn = Faceforward(dgBump->nn, dgGeom.nn);
}

void BumpMapping::Bump(const DifferentialGeometry& dgGeom, const DifferentialGeometry& dgShading,
	DifferentialGeometry* dgBump) const
{
	if (bumpMap)
		Material::Bump(bumpMap, dgGeom, dgShading, dgBump);
	else
		*dgBump = dgShading;
}


const float WLD_lambdas[] = {
	400, 405, 410, 415, 420, 425, 430, 435, 440, 445,
	450, 455, 460, 465, 470, 475, 480, 485, 490, 495,
	500, 505, 510, 515, 520, 525, 530, 535, 540, 545,
	550, 555, 560, 565, 570, 575, 580, 585, 590, 595,
	600, 605, 610, 615, 620, 625, 630, 635, 640, 645,
	650, 655, 660, 665, 670, 675, 680, 685, 690, 695,
	700
};


LayeredMaterialWrapper::LayeredMaterialWrapper(const Reference<LayeredMaterial>& layeredMaterial,
	int layerIndex)
	: layerIndex(layerIndex), layeredMaterial(layeredMaterial)
{
}

int LayeredMaterialWrapper::GetLayerIndex() const {
	return layerIndex;
}

BSDF* LayeredMaterialWrapper::GetBSDF(const DifferentialGeometry &dgGeom,
	const DifferentialGeometry &dgShading, MemoryArena &arena) const
{
	return layeredMaterial->GetLayeredBSDF(layerIndex,
		dgGeom, dgShading, arena);
}

BSSRDF* LayeredMaterialWrapper::GetBSSRDF(const DifferentialGeometry &dgGeom,
	const DifferentialGeometry &dgShading, MemoryArena &arena) const
{
	return layeredMaterial->GetLayeredBSSRDF(layerIndex,
		dgGeom, dgShading, arena);
}
