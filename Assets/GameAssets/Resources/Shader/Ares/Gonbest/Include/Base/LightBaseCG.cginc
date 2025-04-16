/*=============================================================
Author:gzg
Date:2019-08-20
Desc:与灯光有关的计算,包括聚光灯计算,点光源计算等等
=============================================================*/

#ifndef GONBEST_LIGHTBASE_CG_INCLUDED
#define GONBEST_LIGHTBASE_CG_INCLUDED
#include "UnityCG.cginc"


//获取聚光灯的强度值
/*
L:光线与点的连线方向
LightDir:灯光原始的方向
    // x = cos(spotAngle/2) or -1 for non-spot
    // y = 1/cos(spotAngle/4) or 1 for non-spot
    // z = quadratic attenuation 二次衰减
    // w = range*range
FallOffCosHalfThetaPHi:θ,φ 强度递减的参数
*/
inline float GetSpotAtten(float3 L, float3 LightDir,in float3 FallOffCosHalfThetaPHi)
{
	float DoL = saturate(dot(LightDir,-L)); /*光线方向和灯方向的夹角*/
	return pow(saturate(DoL*FallOffCosHalfThetaPHi.y+FallOffCosHalfThetaPHi.z), FallOffCosHalfThetaPHi.x);		
}

//获取点光源的强度--根据距离远近
/*
Dist:灯和像素点的距离
LitAtten:灯光的强度
LitRange :灯光的范围;
*/
inline float GetPointAtten(float Dist, float LitAtten, float LitRange)
{
	float Atten = saturate((LitRange - Dist)/LitRange) ;		
	return Atten * Atten * LitAtten;
}

//计算强度
/*
lightPos:灯光位置
viewPos:顶点位置,View的坐标系
viewN:法线,View的坐标系

    // x = cos(spotAngle/2) or -1 for non-spot
    // y = 1/cos(spotAngle/4) or 1 for non-spot
    // z = quadratic attenuation 二次衰减
    // w = range*range
lightAtten:灯光强度

spotDir:聚光方向
spotLight:是否使用聚光灯
*/
inline float GetUnityAtten(float4 lightPos,float3 viewPos,float3 viewN,float3 lightAtten,float3 spotDir,bool spotLight)
{
    float3 toLight = lightPos.xyz - viewPos.xyz * lightPos.w;
    float lengthSq = dot(toLight, toLight);

    // don't produce NaNs if some vertex position overlaps with the light
    lengthSq = max(lengthSq, 0.000001);

    toLight *= rsqrt(lengthSq);

    float atten = 1.0 / (1.0 + lengthSq * lightAtten.z);
    if (spotLight)
    {
        float rho = max (0, dot(toLight, spotDir.xyz));
        float spotAtt = (rho -lightAtten.x) * lightAtten.y;
        atten *= saturate(spotAtt);
    }

    float diff = max (0, dot (viewN, toLight));
    return diff * atten;
}

#endif //GONBEST_LIGHTBASE_CG_INCLUDED