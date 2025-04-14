/*
Author:gzg
Date:2019-08-20
Desc:一些片元中执行的常用函数
*/

#ifndef GONBEST_PIXELUTILS_CG_INCLUDED
#define GONBEST_PIXELUTILS_CG_INCLUDED
#include "UnityCG.cginc"
#include "../Base/CommonCG.cginc"
#include "../Base/NormalCG.cginc"


/*===============在Pixel函数中执行的一些功能函数===============*/
//通过法线纹理获取法线
inline float3 GetWorldNormalFromBump(float4 bumpColor, float bumpScale,float3 WT,float3 WB,float3 WN)
{
    float3 TN = GBUnpackScaleNormal(bumpColor,bumpScale);
    return GBNormalizeSafe(float3(WT * TN.x + WB * TN.y + WN * TN.z));			    
}
//获取直射光方向
inline float3 GetWorldUnityLightDir(float3 wp)
{
    return GBNormalizeSafe(_WorldSpaceLightPos0.xyz - _WorldSpaceLightPos0.w * wp); 
}
//获取视线方向
inline float3 GetWorldViewDir(float3 wp)
{
    return GBNormalizeSafe((_WorldSpaceCameraPos.xyz - wp.xyz)); 
}
//获取视线方向
inline float3 GetWorldViewDirWithUI(float3 wp, half isUI)
{
    float3 V = GBNormalizeSafe((_WorldSpaceCameraPos.xyz - wp.xyz)); 
    float3 UIV = GBNormalizeSafe(float3(0,0,-1));
    float isui = step(0.5,isUI);
    return lerp(V,UIV,isui);    
}

inline float3 GetWorldViewDirWithUIEX(float3 wp,float3 vp, half isUI)
{
    float3 V = GBNormalizeSafe((vp.xyz - wp.xyz)); 
    float3 UIV = GBNormalizeSafe(float3(0,0,-1));
    float isui = step(0.5,isUI);
    return lerp(V,UIV,isui);    
}

#endif //GONBEST_PIXELUTILS_CG_INCLUDED