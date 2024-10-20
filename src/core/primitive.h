
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

#if defined(_MSC_VER)
#pragma once
#endif

#ifndef PBRT_CORE_PRIMITIVE_H
#define PBRT_CORE_PRIMITIVE_H

// core/primitive.h*
#include "pbrt.h"
#include "shape.h"
#include "material.h"

class LayeredGeometricPrimitive;

// Primitive Declarations
class Primitive : public ReferenceCounted {
public:
    // Primitive Interface
    Primitive() : primitiveId(nextprimitiveId++) { }
    virtual ~Primitive();
    virtual BBox WorldBound() const = 0;
    virtual bool CanIntersect() const;
    virtual bool Intersect(const Ray &r, Intersection *in) const = 0;
	virtual bool IntersectExcept(const Ray &r, Intersection* in, uint32_t primitiveId) const {
		if (this->primitiveId == primitiveId) return false;
		return Intersect(r, in);
	}
    virtual bool IntersectP(const Ray &r) const = 0;
    virtual void Refine(vector<Reference<Primitive> > &refined) const;
    void FullyRefine(vector<Reference<Primitive> > &refined) const;
    virtual const AreaLight *GetAreaLight() const = 0;
    virtual BSDF *GetBSDF(const DifferentialGeometry &dg,
        const Transform &ObjectToWorld, MemoryArena &arena) const = 0;
    virtual BSSRDF *GetBSSRDF(const DifferentialGeometry &dg,
        const Transform &ObjectToWorld, MemoryArena &arena) const = 0;
    virtual const MultipoleBSSRDF* GetMultipoleBSSRDF(const DifferentialGeometry &dg,
		const Transform &ObjectToWorld, MemoryArena &arena) const = 0;
	virtual void GetShadingGeometry(const DifferentialGeometry& dg, 
		const Transform &ObjectToWorld, DifferentialGeometry& dgShading) const = 0;
 	// Low-cost RTTI
	virtual LayeredGeometricPrimitive* ToLayered() { return NULL; }
	virtual const LayeredGeometricPrimitive* ToLayered() const { return NULL; }
   // Primitive Public Data
    const uint32_t primitiveId;
protected:
    // Primitive Protected Data
    static uint32_t nextprimitiveId;
};


// GeometricPrimitive Declarations
class GeometricPrimitive : public Primitive {
public:
    // GeometricPrimitive Public Methods
    bool CanIntersect() const;
    void Refine(vector<Reference<Primitive> > &refined) const;
    virtual BBox WorldBound() const;
    virtual bool Intersect(const Ray &r, Intersection *isect) const;
    virtual bool IntersectP(const Ray &r) const;
    GeometricPrimitive(const Reference<Shape> &s,
                       const Reference<Material> &m, const AreaLight *a);
    const AreaLight *GetAreaLight() const;
    BSDF *GetBSDF(const DifferentialGeometry &dg,
                  const Transform &ObjectToWorld, MemoryArena &arena) const;
    BSSRDF *GetBSSRDF(const DifferentialGeometry &dg,
                      const Transform &ObjectToWorld, MemoryArena &arena) const;
    const MultipoleBSSRDF* GetMultipoleBSSRDF(const DifferentialGeometry &dg,
		const Transform &ObjectToWorld, MemoryArena &arena) const override;
	void GetShadingGeometry(const DifferentialGeometry& dg,
		const Transform &ObjectToWorld, DifferentialGeometry& dgShading) const override;
	const Shape* GetShape() const;
	const Material* GetMaterial() const;
protected:
    // GeometricPrimitive Private Data
    Reference<Shape> shape;
    Reference<Material> material;
private:
    // GeometricPrimitive Private Data
    const AreaLight *areaLight;
};


class LayeredGeometricPrimitive : public GeometricPrimitive {
public:
    // LayeredGeometricPrimitive Public Methods
	LayeredGeometricPrimitive(const Reference<Shape>& s,
		const Reference<LayeredMaterial>& m, const AreaLight* a);
	virtual bool IntersectInternal(const Ray& r, uint32_t primitiveId,
		Intersection* isect, int* layerIndex) const = 0;
	virtual BSDF *GetLayeredBSDF(int layerIndex,
		const DifferentialGeometry &dg,
		const Transform &ObjectToWorld, MemoryArena &arena) const = 0;
	virtual BSSRDF *GetLayeredBSSRDF(int layerIndex,
		const DifferentialGeometry &dg,
		const Transform &ObjectToWorld, MemoryArena &arena) const = 0;
	LayeredGeometricPrimitive* ToLayered() override { return this; }
	const LayeredGeometricPrimitive* ToLayered() const override { return this; }
};



// TransformedPrimitive Declarations
class TransformedPrimitive : public Primitive {
public:
    // TransformedPrimitive Public Methods
    TransformedPrimitive(Reference<Primitive> &prim,
                         const AnimatedTransform &w2p)
        : primitive(prim), WorldToPrimitive(w2p) { }
    bool Intersect(const Ray &r, Intersection *in) const;
    bool IntersectP(const Ray &r) const;
    const AreaLight *GetAreaLight() const { return NULL; }
    BSDF *GetBSDF(const DifferentialGeometry &dg,
                  const Transform &ObjectToWorld, MemoryArena &arena) const {
        return NULL;
    }
    BSSRDF *GetBSSRDF(const DifferentialGeometry &dg,
                  const Transform &ObjectToWorld, MemoryArena &arena) const {
        return NULL;
    }
    const MultipoleBSSRDF* GetMultipoleBSSRDF(const DifferentialGeometry &dg,
		const Transform &ObjectToWorld, MemoryArena &arena) const override
	{
		return NULL;
	}
	void GetShadingGeometry(const DifferentialGeometry& dg,
		const Transform &ObjectToWorld, DifferentialGeometry& dgShading) const override
	{
		primitive->GetShadingGeometry(dg, ObjectToWorld, dgShading);
	}
    BBox WorldBound() const {
        return WorldToPrimitive.MotionBounds(primitive->WorldBound(), true);
    }
private:
    // TransformedPrimitive Private Data
    Reference<Primitive> primitive;
    const AnimatedTransform WorldToPrimitive;
};



// Aggregate Declarations
class Aggregate : public Primitive {
public:
    // Aggregate Public Methods
    const AreaLight *GetAreaLight() const;
    BSDF *GetBSDF(const DifferentialGeometry &dg,
                  const Transform &, MemoryArena &) const;
    BSSRDF *GetBSSRDF(const DifferentialGeometry &dg,
                  const Transform &, MemoryArena &) const;
    const MultipoleBSSRDF* GetMultipoleBSSRDF(const DifferentialGeometry &dg,
		const Transform &ObjectToWorld, MemoryArena &arena) const override;
	void GetShadingGeometry(const DifferentialGeometry& dg,
		const Transform &ObjectToWorld, DifferentialGeometry& dgShading) const override;
};


GeometricPrimitive* CreateGeometricPrimitive(
	const Reference<Shape>& s, const Reference<Material>& m,
	const AreaLight* a);

#endif // PBRT_CORE_PRIMITIVE_H
