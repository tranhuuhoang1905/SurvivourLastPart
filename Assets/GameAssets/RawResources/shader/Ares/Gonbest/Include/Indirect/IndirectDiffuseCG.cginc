/*
Author:gzg
Date:2019-08-20
Desc:间接光的漫反射处理,其实就是lightmap,sh,shadow等处理.
*/
#ifndef GONBEST_INDIRECTDIFFUSE_CG_INCLUDED
#define GONBEST_INDIRECTDIFFUSE_CG_INCLUDED
#include "../Base/CommonCG.cginc"
#include "SHLightCG.cginc"
#include "UnityLightingCommon.cginc"


/*
 环境光的散射光处理
 lightmap:lightmap的值
 shadowAtten:阴影强度
 wNormal:世界坐标系法线
*/
inline half3 ApplySubtractiveLighting (half3 lightmap, half shadowAtten, half3 shadowColor, half3 shadowStrength, half3 wNormal)
{
    ///让我们试着让实时阴影在一个表面上工作，这个表面已经包含了烘烤的光照和来自主太阳光的阴影。
    //half3 shadowColor = unity_ShadowColor.rgb;
    //half shadowStrength = _LightShadowData.x;

    // 1)通过减去实时阴影遮挡处的估计光贡献，计算阴影中的可能值:
    // a)保留其他烘烤过的灯和光线反射
    // b)消除背向光线的几何体上的阴影
    // 2)用户定义的阴影颜色。
    // 3)选择原始的lightmap值，如果它是最暗的。

    // Summary:
    // 1) Calculate possible value in the shadow by subtracting estimated light contribution from the places occluded by realtime shadow:
    //      a) preserves other baked lights and light bounces
    //      b) eliminates shadows on the geometry facing away from the light
    // 2) Clamp against user defined ShadowColor.
    // 3) Pick original lightmap value, if it is the darkest one.


    // 1) Gives good estimate of illumination as if light would've been shadowed during the bake.
    //    Preserves bounce and other baked lights
    //    No shadows on the geometry facing away from the light
    half ndotl = dot (wNormal, _WorldSpaceLightPos0.xyz);    
    half3 subtractedLightmap = lightmap - ndotl * (1- shadowAtten) * _LightColor0.rgb;

    // 2) Allows user to define overall ambient of the scene and control situation when realtime shadow becomes too dark.
    half3 realtimeShadow = max(subtractedLightmap, shadowColor);
    realtimeShadow = lerp(realtimeShadow, lightmap, shadowStrength);

    // 3) Pick darkest color
    return min(lightmap, realtimeShadow);
}

/*
间接漫反射
ambient:环境光
shadowAtten:阴影的强度
worldpos:世界坐标系位置
wNormal:世界坐标系法线
lightmapUV:lightmap的uv
*/
inline half3 IndirectDiffuse(half3 ambient, half shadowAtten, half3 shadowColor, half3 shadowStrength, half3 wPos, half3 wNormal,half4 lightmapUV)
{
    half3 IndirectDiffuse = (half3)0;
    #ifdef UNITY_SHOULD_SAMPLE_SH
        //使用球谐光处理
		IndirectDiffuse += ShadeSHPerPixel(wNormal, ambient, wPos);
	#endif
    
    #ifdef LIGHTMAP_ON
        //使用烘培贴图
        // Baked lightmaps
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV.xy);
        half3 bakedColor = DecodeLightmap(bakedColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, lightmapUV.xy);
            IndirectDiffuse += DecodeDirectionalLightmap (bakedColor, bakedDirTex, wNormal);
        #else // not directional lightmap
            IndirectDiffuse += bakedColor;
        #endif
        
        #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)            
            IndirectDiffuse = ApplySubtractiveLighting ( IndirectDiffuse, shadowAtten, shadowColor, shadowStrength, wNormal);
        #endif
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        //使用动态烘培贴图
        // Dynamic lightmaps
        half4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, lightmapUV.zw);
        half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, lightmapUV.zw);
            IndirectDiffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, wNormal);
        #else
            IndirectDiffuse += realtimeColor;
        #endif
    #endif

    

    IndirectDiffuse = ApplySubtractiveLighting ( IndirectDiffuse, shadowAtten, shadowColor, shadowStrength, wNormal);

    return IndirectDiffuse;
}



#endif //GONBEST_INDIRECTDIFFUSE_CG_INCLUDED