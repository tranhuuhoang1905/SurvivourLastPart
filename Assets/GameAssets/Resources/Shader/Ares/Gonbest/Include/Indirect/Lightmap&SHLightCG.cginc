/*
Author:gzg
Date:2019-08-20
Desc:lightmap和SH的一些处理
     其中:球谐光的处理,用于模拟环境光的散射效果,要想探针有效果,需要把shader的lightmode设置 例如: Tags { "LightMode" = "ForwardBase" }
*/
#ifndef GONBEST_LIGHTMAP_SHLIGHT_CG_INCLUDED
#define GONBEST_LIGHTMAP_SHLIGHT_CG_INCLUDED
#include "../Base/CommonCG.cginc"
#include "../Base/Linear&GammaCG.cginc"
#include "VertexLitCG.cginc"
#include "UnityCG.cginc"
#include "HLSLSupport.cginc"

//-----------------------------------球谐光(SH)的处理--------------------------------------------------//

// normal should be GBNormalizeSafed, w=1.0
half3 GBSHEvalLinearL0L1 (half4 normal)
{
    half3 x;

    // Linear (L1) + constant (L0) polynomial terms
    x.r = dot(unity_SHAr,normal);
    x.g = dot(unity_SHAg,normal);
    x.b = dot(unity_SHAb,normal);

    return x;
}

// normal should be GBNormalizeSafed, w=1.0
half3 GBSHEvalLinearL2 (half4 normal)
{
    half3 x1, x2;
    // 4 of the quadratic (L2) polynomials
    half4 vB = normal.xyzz * normal.yzzx;
    x1.r = dot(unity_SHBr,vB);
    x1.g = dot(unity_SHBg,vB);
    x1.b = dot(unity_SHBb,vB);

    // Final (5th) quadratic (L2) polynomial
    half vC = normal.x*normal.x - normal.y*normal.y;
    x2 = unity_SHC.rgb * vC;

    return x1 + x2;
}


// normal should be GBNormalizeSafed, w=1.0
// output in active color space
half3 GBShadeSH9 (half4 normal)
{
    // Linear + constant polynomial terms
    half3 res = GBSHEvalLinearL0L1 (normal);

    // Quadratic polynomials
    res += GBSHEvalLinearL2 (normal);
    res = GONBEST_LINEAR_TO_GAMMA(res); 
    return res;
}

//在定点执行球谐光
half3 GBShadeSHPerVertex (half3 normal, half3 ambient)
{
    #if UNITY_SAMPLE_FULL_SH_PER_PIXEL
        // Completely per-pixel
        // nothing to do here
    #elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        // Completely per-vertex
        ambient += max(half3(0,0,0), GBShadeSH9 (half4(normal, 1.0)));
    #else
        // L2 per-vertex, L0..L1 & gamma-correction per-pixel

        // NOTE: SH data is always in Linear AND calculation is split between vertex & pixel
        // Convert ambient to Linear and do final gamma-correction at the end (per-pixel)
        ambient = GONBEST_GAMMA_TO_LINEAR(ambient);
        ambient += SHEvalLinearL2 (half4(normal, 1.0));     // no max since this is only L2 contribution
    #endif

    return ambient;
}


#if UNITY_LIGHT_PROBE_PROXY_VOLUME

// normal should be GBNormalizeSafed, w=1.0
half3 GBSHEvalLinearL0L1_SampleProbeVolume (half4 normal, float3 worldPos)
{
    const float transformToLocal = unity_ProbeVolumeParams.y;
    const float texelSizeX = unity_ProbeVolumeParams.z;

    //The SH coefficients textures and probe occlusion are packed into 1 atlas.
    //-------------------------
    //| ShR | ShG | ShB | Occ |
    //-------------------------

    float3 position = (transformToLocal == 1.0f) ? mul(unity_ProbeVolumeWorldToObject, float4(worldPos, 1.0)).xyz : worldPos;
    float3 texCoord = (position - unity_ProbeVolumeMin.xyz) * unity_ProbeVolumeSizeInv.xyz;
    texCoord.x = texCoord.x * 0.25f;

    // We need to compute proper X coordinate to sample.
    // Clamp the coordinate otherwize we'll have leaking between RGB coefficients
    float texCoordX = clamp(texCoord.x, 0.5f * texelSizeX, 0.25f - 0.5f * texelSizeX);

    // sampler state comes from SHr (all SH textures share the same sampler)
    texCoord.x = texCoordX;
    half4 SHAr = UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord);

    texCoord.x = texCoordX + 0.25f;
    half4 SHAg = UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord);

    texCoord.x = texCoordX + 0.5f;
    half4 SHAb = UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord);

    // Linear + constant polynomial terms
    half3 x1;
    x1.r = dot(SHAr, normal);
    x1.g = dot(SHAg, normal);
    x1.b = dot(SHAb, normal);

    return x1;
}
#endif

//在pixel来执行球谐光
half3 GBShadeSHPerPixel (half3 normal, half3 ambient, float3 worldPos)
{
    half3 ambient_contrib = 0.0;

    #if UNITY_SAMPLE_FULL_SH_PER_PIXEL
        // Completely per-pixel
        #if UNITY_LIGHT_PROBE_PROXY_VOLUME
            if (unity_ProbeVolumeParams.x == 1.0)
                ambient_contrib = GBSHEvalLinearL0L1_SampleProbeVolume(half4(normal, 1.0), worldPos);
            else
                ambient_contrib = GBSHEvalLinearL0L1(half4(normal, 1.0));
        #else
            ambient_contrib = GBSHEvalLinearL0L1(half4(normal, 1.0));
        #endif

            ambient_contrib += GBSHEvalLinearL2(half4(normal, 1.0));

            ambient += max(half3(0, 0, 0), ambient_contrib);

        ambient = GONBEST_LINEAR_TO_GAMMA(ambient);     
    #elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        // Completely per-vertex
        // nothing to do here. Gamma conversion on ambient from SH takes place in the vertex shader, see ShadeSHPerVertex.        
    #else
        // L2 per-vertex, L0..L1 & gamma-correction per-pixel
        // Ambient in this case is expected to be always Linear, see ShadeSHPerVertex()
        #if UNITY_LIGHT_PROBE_PROXY_VOLUME
            if (unity_ProbeVolumeParams.x == 1.0)
                ambient_contrib = GBSHEvalLinearL0L1_SampleProbeVolume (half4(normal, 1.0), worldPos);
            else
                ambient_contrib = GBSHEvalLinearL0L1 (half4(normal, 1.0));
        #else
            ambient_contrib = GBSHEvalLinearL0L1 (half4(normal, 1.0));
        #endif

        ambient = max(half3(0, 0, 0), ambient+ambient_contrib);     // include L2 contribution in vertex shader before clamp.
        ambient = GONBEST_LINEAR_TO_GAMMA(ambient);
    #endif

    return ambient;
}

//球谐光的宏处理
#if defined(LIGHTPROBE_SH)

        #define GONBEST_SH_COORDS(idx1) float3 __ambientColor : TEXCOORD##idx1;        
        #define GONBEST_TRANSFER_SH(o,wn,wpos)\
            float3 __ambientcolor = GONBEST_TRANSFER_VERTEXLIT(wn,wpos);\
            o.__ambientColor = GBShadeSHPerVertex(wn,__ambientcolor);         

        #define GONBEST_APPLY_SH_COLOR(i,wn,wpos,idiff) idiff = GBShadeSHPerPixel(wn,i.__ambientColor,wpos.xyz);
#else
        #define GONBEST_SH_COORDS(idx1)
        #define GONBEST_TRANSFER_SH(o,wn,wpos)
        #define GONBEST_APPLY_SH_COLOR(i,wn,wpos,idiff) 
#endif

//-----------------------------------烘培贴图(Lightmap)的处理--------------------------------------------------//
#if defined(LIGHTMAP_ON)
    #define GONBEST_CALC_LIGHTMAP_UV(uv2) uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw
    #define GONBEST_APPLY_LIGHTMAP_COLOR(lmuv,idiff) idiff = DecodeLightmap(UNITY_SAMPLE_TEX2D( unity_Lightmap, lmuv.xy));
#else
    #define GONBEST_CALC_LIGHTMAP_UV(uv2) (float2)0
    #define GONBEST_APPLY_LIGHTMAP_COLOR(lmuv,idiff)
#endif 

//-----------------------------------间接漫反射光的间接处理--------------------------------------------------//
//对间接漫反射光的顶点函数中的处理
inline float4 GBTransferInDirectDiffuse(float3 wNormal,float3 wPos, float2 vTexcoord1)
{
    float4 ret = (float4)0;
    #if defined(LIGHTMAP_ON)         
       ret.xy = vTexcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
    #elif defined(LIGHTPROBE_SH)
        float3 ambientcolor = GONBEST_TRANSFER_VERTEXLIT(wNormal,wPos);
        ret.xyz = GBShadeSHPerVertex(wNormal,ambientcolor); 
    #endif  
    return ret;  
}

//针对间接漫反射光的颜色处理
inline float3 GBApplyInDirectDiffuseColor(float3 wNormal,float3 wPos,float4 lmOrAmbient)
{
    #if defined(LIGHTMAP_ON)
        return DecodeLightmap(UNITY_SAMPLE_TEX2D( unity_Lightmap, lmOrAmbient.xy));
    #elif defined(LIGHTPROBE_SH)
        return GBShadeSHPerPixel(wNormal,lmOrAmbient.xyz,wPos.xyz);
    #endif
    return (float3)1;
}

//间接漫反射光的处理
#if defined(_GONBEST_INDIRECT_DIFFUSE_ON)
    #define GONBEST_INDIRECT_DIFFUSE_COORDS(idx1) float4 __LMorSH : TEXCOORD##idx1; 
    #define GONBEST_TRANSFER_INDIRECT_DIFFUSE(o,wn,wpos,uv2) o.__LMorSH = GBTransferInDirectDiffuse(wn,wpos,uv2);
    #define GONBEST_APPLY_INDIRECT_DIFFUSE_COLOR(i,wn,wpos,idiff) idiff = GBApplyInDirectDiffuseColor(wn,wpos,i.__LMorSH);
#else
    #define GONBEST_INDIRECT_DIFFUSE_COORDS(idx1)
    #define GONBEST_TRANSFER_INDIRECT_DIFFUSE(o,wn,wpos,uv2)
    #define GONBEST_APPLY_INDIRECT_DIFFUSE_COLOR(i,wn,wpos,idiff)
#endif

#endif//GONBEST_LIGHTMAP_SHLIGHT_CG_INCLUDED