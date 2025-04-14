/*
Author:gzg
Date:2019-08-20
Desc:GGX的高光公式
*/
#ifndef GONBEST_GGX_CG_INCLUDED
#define GONBEST_GGX_CG_INCLUDED
#include "../Base/CommonCG.cginc"

/*=============================D=========================================*/
//GGX的动态分布函数D的公式
inline float GBGGXTerm (float NdotH, float roughness)
{
    float a2 = roughness * roughness;
    float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
    return GONBEST_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
                                            // therefore epsilon is smaller than what can be represented by half
}

/*=============================V=========================================*/
//GGX的动态阴影V的公式
// Ref: http://jcgt.org/published/0003/02/03/paper.pdf
inline float GBSmithJointGGXVisibilityTerm (float NdotL, float NdotV, float roughness)
{
#if 0
    //原始公式
    // Original formulation:
    //  lambda_v    = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
    //  lambda_l    = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
    //  G           = 1 / (1 + lambda_v + lambda_l);

    // Reorder code to be more optimal
    half a          = roughness;
    half a2         = a * a;

    half lambdaV    = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
    half lambdaL    = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

    // Simplify visibility term: (2.0f * NdotL * NdotV) /  ((4.0f * NdotL * NdotV) * (lambda_v + lambda_l + 1e-5f));
    return 0.5f / (lambdaV + lambdaL + 1e-5f);  // This function is not intended to be running on Mobile,
                                                // therefore epsilon is smaller than can be represented by half
#else
    // Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
    float a = roughness;
    float lambdaV = NdotL * (NdotV * (1 - a) + a);
    float lambdaL = NdotV * (NdotL * (1 - a) + a);

    return 0.5f / (lambdaV + lambdaL + 1e-5f);
#endif
}

/*===================================SpecularTerm==============================================*/

//GGX的高光公式2 --- 使用在手机上,效率更高一些
inline float GBGGXSpecularTermOptimize(float nh, float lh, float roughness)
{
    half a = roughness;
    float a2 = a*a;
    float d = nh * nh * (a2 - 1.f) + 1.00001f;
#ifdef UNITY_COLORSPACE_GAMMA
    // Tighter approximation for Gamma only rendering mode!
    // DVF = sqrt(DVF);
    // DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
    return a / (max(0.32f, lh) * (1.5f + roughness) * d);
#else
    return a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4);
#endif
}

//GGX的高光公式1
inline float GBGGXSpecularTerm(float nh, float nl, float nv, float roughness)
{
    float V = GBSmithJointGGXVisibilityTerm(nl,nv,roughness);
    float D = GBGGXTerm (nh, roughness);

#ifdef UNITY_COLORSPACE_GAMMA
        return sqrt(max(1e-4h, V * D * GONBEST_PI));
#else
        return V * D * GONBEST_PI;
#endif    
}


#endif //GONBEST_GGX_CG_INCLUDED