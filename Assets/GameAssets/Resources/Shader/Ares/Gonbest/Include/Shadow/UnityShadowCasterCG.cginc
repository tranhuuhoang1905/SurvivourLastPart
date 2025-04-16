/*
Author:gzg
Date:2019-08-23
Desc:为Unity的阴影生成的ShadowMap的所需的一些函数功能.
    生成Unity的Shadowmap需要在Pass上增加 Tags{ "LightMode" = "ShadowCaster" }
*/

#ifndef GONBEST_UNITYSHADOWCASTERCG_CG_INCLUDED
#define GONBEST_UNITYSHADOWCASTERCG_CG_INCLUDED

#include "../Base/CommonCG.cginc"
#include "../Base/MathCG.cginc"
 

    // Shadow caster pass helpers

    float4 GBUnityEncodeCubeShadowDepth (float z)
    {
        #ifdef UNITY_USE_RGBA_FOR_POINT_SHADOWS
        return GBEncodeFloatRGBA(min(z, 0.999));
        #else
        return z;
        #endif
    }

    float GBUnityDecodeCubeShadowDepth (float4 vals)
    {
        #ifdef UNITY_USE_RGBA_FOR_POINT_SHADOWS
        return GBDecodeFloatRGBA (vals);
        #else
        return vals.r;
        #endif
    }


    float4 GBUnityClipSpaceShadowCasterPos(float4 vertex, float3 normal)
    {
        float4 wPos = mul(unity_ObjectToWorld, vertex);

        if (unity_LightShadowBias.z != 0.0)
        {
            float3 wNormal = mul(float4(normal,0),unity_WorldToObject).xyz;
            float3 wLight = GBNormalizeSafe(_WorldSpaceLightPos0.xyz - wPos.xyz * _WorldSpaceLightPos0.w);

            // apply normal offset bias (inset position along the normal)
            // bias needs to be scaled by sine between normal and light direction
            // (http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/)
            //
            // unity_LightShadowBias.z contains user-specified normal offset amount
            // scaled by world space texel size.

            float shadowCos = dot(wNormal, wLight);
            float shadowSine = sqrt(1-shadowCos*shadowCos);
            float normalBias = unity_LightShadowBias.z * shadowSine;

            wPos.xyz -= wNormal * normalBias;
        }

        return mul(UNITY_MATRIX_VP, wPos);
    }
    // Legacy, not used anymore; kept around to not break existing user shaders
    float4 GBUnityClipSpaceShadowCasterPos(float3 vertex, float3 normal)
    {
        return GBUnityClipSpaceShadowCasterPos(float4(vertex, 1), normal);
    }


    float4 GBUnityApplyLinearShadowBias(float4 clipPos)
    {
    #if defined(UNITY_REVERSED_Z)

        // For point lights that support depth cube map, the bias is applied in the fragment shader sampling the shadow map.
        // This is because the legacy behaviour for point light shadow map cannot be implemented by offseting the vertex position
        // in the vertex shader generating the shadow map.
    #   if !(defined(SHADOWS_CUBE) && defined(SHADOWS_CUBE_IN_DEPTH_TEX))
        // We use max/min instead of clamp to ensure proper handling of the rare case
        // where both numerator and denominator are zero and the fraction becomes NaN.
        clipPos.z += max(-1, min(unity_LightShadowBias.x / clipPos.w, 0));
    #   endif
        float clamped = min(clipPos.z, clipPos.w*UNITY_NEAR_CLIP_VALUE);
    #else
        clipPos.z += saturate(unity_LightShadowBias.x/clipPos.w);
        float clamped = max(clipPos.z, clipPos.w*UNITY_NEAR_CLIP_VALUE);
    #endif
        clipPos.z = lerp(clipPos.z, clamped, unity_LightShadowBias.y);
        return clipPos;
    }


    #if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
        // Rendering into point light (cubemap) shadows
        #define V2F_SHADOW_CASTER_NOPOS float3 vec : TEXCOORD0;

        #define TRANSFER_SHADOW_CASTER_NOPOS_LEGACY(o,opos)\
                o.vec = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz; \
                opos = UnityObjectToClipPos(v.vertex);

        #define TRANSFER_SHADOW_CASTER_NOPOS(o,opos)\
                o.vec = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;\
                opos = UnityObjectToClipPos(v.vertex);

        #define SHADOW_CASTER_FRAGMENT(i)\
                return GBUnityEncodeCubeShadowDepth ((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);

    #else
        // Rendering into directional or spot light shadows
        #define V2F_SHADOW_CASTER_NOPOS
        // Let embedding code know that V2F_SHADOW_CASTER_NOPOS is empty; so that it can workaround
        // empty structs that could possibly be produced.
        #define V2F_SHADOW_CASTER_NOPOS_IS_EMPTY
        
        #define TRANSFER_SHADOW_CASTER_NOPOS_LEGACY(o,opos) \
                opos = UnityObjectToClipPos(v.vertex.xyz); \
                opos = GBUnityApplyLinearShadowBias(opos);

        #define TRANSFER_SHADOW_CASTER_NOPOS(o,opos) \
                opos = GBUnityClipSpaceShadowCasterPos(v.vertex, v.normal); \
                opos = GBUnityApplyLinearShadowBias(opos);

        #define SHADOW_CASTER_FRAGMENT(i) return 0;
    #endif

    // Declare all data needed for shadow caster pass output (any shadow directions/depths/distances as needed),
    // plus clip space position.
    #define V2F_SHADOW_CASTER V2F_SHADOW_CASTER_NOPOS UNITY_POSITION(pos)

    // Vertex shader part, with support for normal offset shadows. Requires
    // position and normal to be present in the vertex input.
    #define TRANSFER_SHADOW_CASTER_NORMALOFFSET(o) TRANSFER_SHADOW_CASTER_NOPOS(o,o.pos)

    // Vertex shader part, legacy. No support for normal offset shadows - because
    // that would require vertex normals, which might not be present in user-written shaders.
    #define TRANSFER_SHADOW_CASTER(o) TRANSFER_SHADOW_CASTER_NOPOS_LEGACY(o,o.pos)



#endif