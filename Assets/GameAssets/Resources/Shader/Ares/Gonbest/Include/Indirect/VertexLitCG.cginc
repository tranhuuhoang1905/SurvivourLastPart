/*=================================================================
Author:gzg
Date:2019-08-20
Desc:顶点光源处理,需要把shader的lightmode设置
例如: Tags { "LightMode" = "ForwardBase" }
==================================================================*/
#ifndef GONBEST_VERTEXLIT_CG_INCLUDED
#define GONBEST_VERTEXLIT_CG_INCLUDED
#include "UnityShaderVariables.cginc"
#include "../Base/MathCG.cginc"

// Used in ForwardBase pass: Calculates diffuse lighting from 4 point lights, with data packed in a special way.
float3 GBShade4PointLights (
    float4 lightPosX, float4 lightPosY, float4 lightPosZ,
    float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
    float4 lightAttenSq,
    float3 pos, float3 normal)
{
    // to light vectors
    float4 toLightX = lightPosX - pos.x;
    float4 toLightY = lightPosY - pos.y;
    float4 toLightZ = lightPosZ - pos.z;
    // squared lengths
    float4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;
    // don't produce NaNs if some vertex position overlaps with the light
    lengthSq = max(lengthSq, 0.000001);

    // NdotL
    float4 ndotl = 0;
    ndotl += toLightX * normal.x;
    ndotl += toLightY * normal.y;
    ndotl += toLightZ * normal.z;
    // correct NdotL
    float4 corr = rsqrt(lengthSq);
    ndotl = max (float4(0,0,0,0), ndotl * corr);
    // attenuation
    float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
    float4 diff = ndotl * atten;
    // final color
    float3 col = 0;
    col += lightColor0 * diff.x;
    col += lightColor1 * diff.y;
    col += lightColor2 * diff.z;
    col += lightColor3 * diff.w;
    return col;
}

// Used in Vertex pass: Calculates diffuse lighting from lightCount lights. Specifying true to spotLight is more expensive
// to calculate but lights are treated as spot lights otherwise they are treated as point lights.
float3 GBShadeVertexLightsFull (float4 vertex, float3 normal, int lightCount, bool spotLight)
{
    float3 viewpos = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(vertex.xyz, 1.0))).xyz; 
    float3 viewN = GBNormalizeSafe (mul ((float3x3)UNITY_MATRIX_IT_MV, normal));

    float3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
    for (int i = 0; i < lightCount; i++) {
        float3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
        float lengthSq = dot(toLight, toLight);

        // don't produce NaNs if some vertex position overlaps with the light
        lengthSq = max(lengthSq, 0.000001);

        toLight *= rsqrt(lengthSq);

        float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
        if (spotLight)
        {
            float rho = max (0, dot(toLight, unity_SpotDirection[i].xyz));
            float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
            atten *= saturate(spotAtt);
        }

        float diff = max (0, dot (viewN, toLight));
        lightColor += unity_LightColor[i].rgb * (diff * atten);
    }
    return lightColor;
}

//顶点光计算处理
float3 GBShadeVertexLights (float4 vertex, float3 normal)
{
    return GBShadeVertexLightsFull (vertex, normal, 4, false);
}


//顶点色的处理
#if defined (VERTEXLIGHT_ON)
    #define GONBEST_TRANSFER_VERTEXLIT(wn,wpos) GBShade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,unity_4LightAtten0, wpos, wn)
#else
    #define GONBEST_TRANSFER_VERTEXLIT(wn,wpos) (float3)0
#endif

#endif