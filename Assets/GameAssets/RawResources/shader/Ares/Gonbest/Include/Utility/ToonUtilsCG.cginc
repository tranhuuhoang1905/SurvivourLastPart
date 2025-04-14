#ifndef GONBEST_TOONUTILS1_CG_INCLUDED
#define GONBEST_TOONUTILS1_CG_INCLUDED
/*卡通的处理效果*/

#include "../Base/RampCG.cginc"

//卡通漫反射的后处理
#if defined(_GONBSE_TOON_DIFFUSE_ON)
    //漫反射进行分阶的阈值
    float _DiffRampThreshold = 0;
    //漫反射进行分阶的光滑度区间
    float _DiffRampSmooth = 0;
    //漫反射中光照的部分颜色
    float3 _DiffRampLightColor ;
    //漫反射阴影的部分颜色，其中他的w分量，用于处理高光和阴影的差值
    float4 _DiffRampShadowColor ;

    //diffcolor就是漫反射的颜色，nol漫反射率。
    #define GONBEST_APPLY_RAMP_DIFFUSE(diffcolor,nol)\
                float __diffRamp = RampTwoStep(nol,_DiffRampThreshold,_DiffRampSmooth);\
                float3 __diffColor = lerp(_DiffRampLightColor.rgb,_DiffRampShadowColor.rgb,_DiffRampShadowColor.a);\
                diffcolor.rgb *=lerp(__diffColor,_DiffRampLightColor.rgb,__diffRamp);

#else
    #define GONBEST_APPLY_RAMP_DIFFUSE(diffcolor,nol) diffcolor *= nol;
#endif

//高光的卡通后处理
#if defined(_GONBSE_TOON_SPECULAR_ON)
     //高光进行分阶的阈值
    float _SpecRampThreshold = 0.5;
    //高光进行分阶的光滑度区间
    float _SpecRampSmooth = 0;

    #define GONBEST_APPLY_RAMP_SPECULAR(specColor,spec)\
        float __specRamp = RampTwoStep(spec,_SpecRampThreshold,_SpecRampSmooth);\
        specColor.rgb *= __specRamp;
#else
    #define GONBEST_APPLY_RAMP_SPECULAR(specColor,spec) specColor.rgb *= spec;
#endif

//边缘光的卡通后处理
#if defined(_GONBSE_TOON_RIM_ON)
    //边缘光进行分阶的阈值
    float _RimRampThreshold = 0;
    //边缘光进行分阶的光滑度区间
    float _RimRampSmooth = 0;

    //diffcolor就是漫反射的颜色，nol漫反射率。
    #define GONBEST_APPLY_RAMP_RIM(rimColor,rim)\
                float __rimRamp = RampTwoStep(rim,_RimRampThreshold,_RimRampSmooth);\
                rimColor.rgb *= __rimRamp;

#else
    #define GONBEST_APPLY_RAMP_RIM(rimColor,rim) rimColor *= rim;
#endif






#endif