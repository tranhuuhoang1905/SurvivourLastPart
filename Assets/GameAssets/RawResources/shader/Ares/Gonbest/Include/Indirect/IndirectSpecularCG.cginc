/*
Author:gzg
Date:2019-08-20
Desc:间接光的高光处理,直接IBL处理
*/
#ifndef GONBEST_INDIRECTSPECULAR_CG_INCLUDED
#define GONBEST_INDIRECTSPECULAR_CG_INCLUDED
#include "../Base/CommonCG.cginc"
#include "UnityCG.cginc"
#include "HLSLSupport.cginc"
#include "UnityImageBasedLighting.cginc"
#include "UnityGlobalIllumination.cginc"

/*
环境中间接光的处理
*/

/*==========================================Indirect Specular=================================================*/
struct GBGISpecularInput
{
    float3 worldPos;
    half3 worldViewDir;  
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION) || defined(UNITY_ENABLE_REFLECTION_BUFFERS)
    float4 boxMin[2];
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
    float4 boxMax[2];
    float4 probePosition[2];
    #endif
    // HDR cubemap properties, use to decompress HDR texture
    float4 probeHDR[2];
};

//定义高光cube的lod的等级
#ifndef GONBEST_SPECCUBE_LOD_STEPS
#define GONBEST_SPECCUBE_LOD_STEPS (6)
#endif

//定义高光cube的lod等级,变量
#ifdef _GONBEST_ENV_MIP_LEVEL_METALIC
    uniform float _EnvCubeMipLevel; 
#endif

//计算mip等级
inline half3 CalcCubeMiplevel(half rough,half metalic)
{
    #ifdef _GONBEST_ENV_MIP_LEVEL_METALIC
        //如果金属度越高,那么lod的值就越小,
        return rough * lerp(_EnvCubeMipLevel,0,metalic);
    #else
        half perceptualRoughness = rough*(1.7 - 0.7*rough);
        return perceptualRoughness / GONBEST_SPECCUBE_LOD_STEPS;
    #endif
}

/*
float4 _XXX_HDR;
使用UNITY_ARGS_TEXCUBE宏,需要通过UNITY_DECLARE_TEXCUBE(XXX)来定义Cube
*/
//通过光滑度来读取环境信息,来自楚留香
inline half3 GlossyEnvironment_CLX(UNITY_ARGS_TEXCUBE(tex),half4 hdr,in float3 R,in half roughness)
{
 
    half3 sampleEnvSpecular=half3(0,0,0);
    half level= roughness /0.17;
    half fSign= R.z > 0;
    half fSign2 = fSign*2 - 1;
    R.xy/= (R.z * fSign2 + 1);
    R.xy= R.xy * half2(0.25,-0.25) + (0.25 + 0.5 * fSign);

    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, R, level);
    return DecodeHDR(rgbm, hdr); 
}

/*
float4 _XXX_HDR;
使用UNITY_ARGS_TEXCUBE宏,需要通过UNITY_DECLARE_TEXCUBE(XXX)来定义Cube
*/
//通过光滑度和金属度来读取环境信息
inline half3 GlossyEnvironment(UNITY_ARGS_TEXCUBE(tex), half4 hdr, half3 R, half roughness,half metalic)
{
   
    half mip = CalcCubeMiplevel(roughness,metalic);    
    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, R, mip);
    return DecodeHDR(rgbm, hdr);
}

//自己定义Cube的间接高光
inline half3 IndirectSpecular_Custom(UNITY_ARGS_TEXCUBE(tex), half4 hdr, half3 R, half roughness,half metalic)
{
    return GlossyEnvironment(UNITY_PASS_TEXCUBE(tex), hdr, R,roughness, metalic);
}



inline half3 GBUnityGI_IndirectSpecular_Custom(UNITY_ARGS_TEXCUBE(cube), half4 cubeHDR, half occlusion, Unity_GlossyEnvironmentData glossIn)
{
    half3 specular;
    #ifdef _GLOSSYREFLECTIONS_OFF
        specular = unity_IndirectSpecColor.rgb;
    #else
        specular = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(cube), cubeHDR, glossIn);
    #endif

    return specular * occlusion;
}

inline half3 GBUnityGI_IndirectSpecular(GBGISpecularInput data, half occlusion, Unity_GlossyEnvironmentData glossIn)
{
    half3 specular;

    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        // we will tweak reflUVW in glossIn directly (as we pass it to Unity_GlossyEnvironment twice for probe0 and probe1), so keep original to pass into BoxProjectedCubemapDirection
        half3 originalReflUVW = glossIn.reflUVW;
        glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);
    #endif

    #ifdef _GLOSSYREFLECTIONS_OFF
        specular = unity_IndirectSpecColor.rgb;
    #else
        half3 env0 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0), data.probeHDR[0], glossIn);
        #ifdef UNITY_SPECCUBE_BLENDING
            const float kBlendFactor = 0.99999;
            float blendLerp = data.boxMin[0].w;
            UNITY_BRANCH
            if (blendLerp < kBlendFactor)
            {
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                    glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[1], data.boxMin[1], data.boxMax[1]);
                #endif

                half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), data.probeHDR[1], glossIn);
                specular = lerp(env1, env0, blendLerp);
            }
            else
            {
                specular = env0;
            }
        #else
            specular = env0;
        #endif
    #endif

    return specular * occlusion;
}


inline float3 IndirectSpecular_Custom (UNITY_ARGS_TEXCUBE(cube), half4 cubeHDR,float3 P,float3 N,float3 V, float3 L, float3 R,float NoL,float smoothness, float3 specColor,float3 lightColor)
{

    Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(smoothness, V, N, specColor);
    //Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
    #if UNITY_STANDARD_SIMPLE
        g.reflUVW = R;
    #endif
    return GBUnityGI_IndirectSpecular_Custom(UNITY_PASS_TEXCUBE(cube), cubeHDR, 1, g);
}



inline float3 IndirectSpecular_Unity (float3 P,float3 N,float3 V, float3 L, float3 R,float NoL,float smoothness, float3 specColor,float3 lightColor)
{
    //创建UnityLight灯光结构
    GBGISpecularInput d;    
    d.worldPos = P;
    d.worldViewDir = V;  
    
    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
    d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
    #endif

    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
    d.boxMax[0] = unity_SpecCube0_BoxMax;
    d.probePosition[0] = unity_SpecCube0_ProbePosition;
    d.boxMax[1] = unity_SpecCube1_BoxMax;
    d.boxMin[1] = unity_SpecCube1_BoxMin;
    d.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif
    
    Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(smoothness, V, N, specColor);
    //Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
    #if UNITY_STANDARD_SIMPLE
        g.reflUVW = R;
    #endif
    return GBUnityGI_IndirectSpecular(d, 1, g);
}

//入射余角的公式
inline float GrazingTerm(float smoothness, half oneMinusReflectivity)
{
    return saturate(smoothness + (1-oneMinusReflectivity));
}

//环境高光强度减少的公式
inline float SurfaceReductionTerm(float roughness,float perceptualRoughness)
{
    #ifdef UNITY_COLORSPACE_GAMMA
        return 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
    #else
        return 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
    #endif
}

//定义宏处理
#define GONBEST_INDIRECT_SPECULAR(cube,cubeHDR,R,roughtness,metalic) GlossyEnvironment(UNITY_PASS_TEXCUBE(cube), cubeHDR, R,roughtness,metalic)

#endif //GONBEST_INDIRECTSPECULAR_CG_INCLUDED