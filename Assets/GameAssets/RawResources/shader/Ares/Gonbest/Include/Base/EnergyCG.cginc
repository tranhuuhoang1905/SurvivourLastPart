/*===============================================================
Author:gzg
Date:2019-08-20
Desc:这里处理关于高光和散射光的能量守恒问题
针对高光有两种颜色值的获取:
1.通过高光贴图,获取高光.通过高光获得散射光值
2.通过金属度来计算高光值,然后在根据反射度来获得散射光值
===============================================================*/

#ifndef GONBEST_ENVBRDF_CG_INCLUDED
#define GONBEST_ENVBRDF_CG_INCLUDED

#include "CommonCG.cginc"

//通过高光贴图获取散射颜色信息和物体的反射度
inline void GetDiffuseFromSpecular(in float3 albedo, in float3 speculuarColor,out float3 diffuseColor, out half oneMinusReflectivity)
{
    //获得反射度 ( 1-reflectivity )
    #if (SHADER_TARGET < 30)    
        oneMinusReflectivity = 1 - speculuarColor.r; // Red channel - 因为大多数金属要么是单晶的，要么是重铬/微黄色的
    #else
        oneMinusReflectivity = 1 - max (max (speculuarColor.r, speculuarColor.g), speculuarColor.b);
    #endif

    //获得散射颜色信息
    diffuseColor = albedo * oneMinusReflectivity;
}


//通过金属度获取散射信息和高光信息,以及物体的反射度
inline void GetDiffuseAndSpecular(in float3 albedo, in float metal, out float3 diffuseColor,out float3 speculuarColor, out half oneMinusReflectivity)
{
    //求 1-reflectivity 
    oneMinusReflectivity = gonbest_ColorSpaceDielectricSpec.a * (1-metal);
    //根据金属度获取高光
    speculuarColor = lerp (gonbest_ColorSpaceDielectricSpec.rgb, albedo, metal);
    //通过反射率直接获得散射光
    diffuseColor =  albedo * oneMinusReflectivity;
}

//获取颜色的亮度，也可以通过它来进行灰化处理
inline float GBLuminance(half3 rgb)
{
    return dot(rgb, gonbest_ColorSpaceLuminance.rgb);
}
	
#endif //GONBEST_ENVBRDF_CG_INCLUDED