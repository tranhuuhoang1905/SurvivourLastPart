/*
Author:gzg
Date:2019-08-20
Desc:场景中雾的处理,包括远近雾和高低雾
*/

#ifndef GONBEST_FOGUTILS_CG_INCLUDED
#define GONBEST_FOGUTILS_CG_INCLUDED
#include "UnityCG.cginc"

#if defined(UNITY_REVERSED_Z)
    #if UNITY_REVERSED_Z == 1
        //D3d with reversed Z => z clip range is [near, 0] -> remapping to [0, far]
        //max is required to protect ourselves from near plane not being correct/meaningfull in case of oblique matrices.
        #define GONBEST_Z_0_FAR_FROM_CLIPSPACE(coord) max(((1.0-(coord)/_ProjectionParams.y)*_ProjectionParams.z),0)
    #else
        //GL with reversed z => z clip range is [near, -far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
        #define GONBEST_Z_0_FAR_FROM_CLIPSPACE(coord) max(-(coord), 0)
    #endif
#elif UNITY_UV_STARTS_AT_TOP
    //D3d without reversed z => z clip range is [0, far] -> nothing to do
    #define GONBEST_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#else
    //Opengl => z clip range is [-near, far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
    #define GONBEST_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#endif

#if defined(FOG_LINEAR)
    // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
    #define GONBEST_CALC_FOG_FACTOR_RAW(coord) float unityFogFactor = (coord) * unity_FogParams.z + unity_FogParams.w
#elif defined(FOG_EXP)
    // factor = exp(-density*z)
    #define GONBEST_CALC_FOG_FACTOR_RAW(coord) float unityFogFactor = unity_FogParams.y * (coord); unityFogFactor = exp2(-unityFogFactor)
#elif defined(FOG_EXP2)
    // factor = exp(-(density*z)^2)
    #define GONBEST_CALC_FOG_FACTOR_RAW(coord) float unityFogFactor = unity_FogParams.x * (coord); unityFogFactor = exp2(-unityFogFactor*unityFogFactor)
#else
    #define GONBEST_CALC_FOG_FACTOR_RAW(coord) float unityFogFactor = 0.0
#endif

#define GONBEST_CALC_FOG_FACTOR(coord) GONBEST_CALC_FOG_FACTOR_RAW(GONBEST_Z_0_FAR_FROM_CLIPSPACE(coord))

#define GONBEST_FOG_COORDS_PACKED(idx, vectype) vectype fogCoord : TEXCOORD##idx;

#define GONBEST_FOG_LERP_COLOR(col,fogCol,fogFac) col.rgb = lerp((fogCol).rgb, (col).rgb, saturate(fogFac))


//雾的坐标参数等定义
#if defined(_GONBEST_HEIGHT_FOG_ON) 
inline float3 _gonbestTransfer(float4 ppos,float3 wpos,float fogYMax,float fogYMin,float fogFar,float fogNear)
#else
inline float3 _gonbestTransfer(float4 ppos,float3 wpos)
#endif
{
    float3 fog = (float3)0;
    #if defined(_GONBEST_HEIGHT_FOG_ON) 
        //求距离        
        float dist =  distance(wpos.xyz, _WorldSpaceCameraPos.xyz);
        //根据距离的衰减
        float hfogAttenByDist = saturate((dist - fogNear)/(fogFar - fogNear));
        //根据高度的衰减
        float hfogAttenByHeight = 1 - saturate((wpos.y - fogYMin) / (fogYMax - fogYMin));

        fog.x = hfogAttenByDist * hfogAttenByHeight * hfogAttenByHeight * hfogAttenByHeight * hfogAttenByHeight;
        fog.y = hfogAttenByHeight * hfogAttenByHeight;        
    #endif	

    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        #if (SHADER_TARGET < 30) || defined(SHADER_API_MOBILE)
            // mobile or SM2.0: calculate fog factor per-vertex
            GONBEST_CALC_FOG_FACTOR(ppos.z); 
            fog.z = unityFogFactor;
        #else
            // SM3.0 and PC/console: calculate fog distance per-vertex, and fog factor per-pixel
            fog.z = ppos.z;
        #endif
    #endif
    
    return fog;
}

//在顶点中调用的宏
#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2) || defined(_GONBEST_HEIGHT_FOG_ON)
    #define GONBEST_FOG_COORDS(idx) GONBEST_FOG_COORDS_PACKED(idx, float3)
    #if defined(_GONBEST_HEIGHT_FOG_ON) 
        uniform float4 _HeightFogInfo;
        #define GONBEST_TRANSFER_FOG(o, ppos, wpos) o.fogCoord.xyz = _gonbestTransfer(ppos , wpos, _HeightFogInfo.y, _HeightFogInfo.x, _HeightFogInfo.w,_HeightFogInfo.z);
    #else
        #define GONBEST_TRANSFER_FOG(o, ppos, wpos) o.fogCoord.xyz = _gonbestTransfer(ppos , wpos);
    #endif    
#else
    #define GONBEST_FOG_COORDS(idx)
    #define GONBEST_TRANSFER_FOG(o, ppos, wpos)
#endif


//雾的颜色渲染处理
inline float3 _gonbestApplyColor(in float3 fog,in float3 mainColor,in float3 unityFogColor)
{
    float3 tmpColor = mainColor.xyz;
    #if defined(_GONBEST_HEIGHT_FOG_ON) 

        float3 hFogColor = lerp(tmpColor, unityFogColor.xyz, fog.y);
        tmpColor = lerp(tmpColor, hFogColor, fog.x);
    #endif    
   
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        #if (SHADER_TARGET < 30) || defined(SHADER_API_MOBILE)
            // mobile or SM2.0: fog factor was already calculated per-vertex, so just lerp the color
            GONBEST_FOG_LERP_COLOR(tmpColor,unityFogColor,fog.z);
        #else
            // SM3.0 and PC/console: calculate fog factor and lerp fog color
            GONBEST_CALC_FOG_FACTOR(fog.z);
            GONBEST_FOG_LERP_COLOR(tmpColor,unityFogColor,unityFogFactor);
        #endif    
    #endif
    return tmpColor;
}

//在偏远中调用的宏
#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2) || defined(_GONBEST_HEIGHT_FOG_ON) 
   #define GONBEST_APPLY_FOG_COLOR(i,mainColor,unityFogColor) mainColor.rgb = _gonbestApplyColor(i.fogCoord,mainColor,unityFogColor);
   #define GONBEST_APPLY_FOG_COLOR_CHECK_UI(i,mainColor,unityFogColor,isui) mainColor.rgb = lerp(_gonbestApplyColor(i.fogCoord,mainColor,unityFogColor), mainColor.rgb, isui);
#else
    #define GONBEST_APPLY_FOG_COLOR(i,mainColor,unityFogColor)
    #define GONBEST_APPLY_FOG_COLOR_CHECK_UI(i,mainColor,unityFogColo,isuir)
#endif

#define GONBEST_APPLY_FOG(i, mainColor) GONBEST_APPLY_FOG_COLOR(i, mainColor,unity_FogColor)
#define GONBEST_APPLY_FOG_CHECK_UI(i, mainColor,isui) GONBEST_APPLY_FOG_COLOR_CHECK_UI(i, mainColor,unity_FogColor,isui)


/*
#ifdef UNITY_PASS_FORWARDADD
    #define GONBEST_APPLY_FOG(i,mainColor,wview) GONBEST_APPLY_FOG_COLOR(i,mainColor,fixed4(0,0,0,0),wview)
#else
    #define GONBEST_APPLY_FOG(i,mainColor,wview) GONBEST_APPLY_FOG_COLOR(i, mainColor,unity_FogColor,wview)
#endif
*/
#endif //GONBEST_FOGUTILS_CG_INCLUDED