/*=============================================================
Author:gzg
Date:2019-08-20
Desc:高度图的处理
    高度图的使用方式:

    float _Height;
    sampler2D _HeightMap

    half h = tex2D(_HeightMap,uv).y;
    float2 offset = GBParallaxOffset(h,_Height,viewDir);

    texUV += offset;
    dumpUV += offset;

    mainColor = tex2D(_MainTex,texUV);
    dumpColor = tex2D(_DumpMap,dumpUV);
=============================================================*/

#ifndef GONBEST_HEIGHTMAP_CG_INCLUDED
#define GONBEST_HEIGHTMAP_CG_INCLUDED


//视差偏移,与UnityCG中的ParallaxOffset一样,不同的是这里使用half替换了之前的float
//这里的返回值,与uv进行相加,对uv进行偏移处理.
//h:HeightMap的一个分量,高度图纹理的的信息
//height:高度图信息的强度 //一般: Range (0.005, 0.08)) = 0.02
//V:归一化后的视线方向
half2 GBParallaxOffset (half h, half height, half3 V)
{
    h = h * height - height/2.0;
    half3 v = V;
    v.z += 0.42;
    return h * (v.xy / v.z);
}


//使用高度图处理
#ifdef(_GONBEST_HEIGHT_MAP_ON)   
    //高度图纹理
    uniform sampler2D _HeightMap;
    //高度图的强度信息
    uniform float _Height = 0.02;

    //初始化高度图的偏移
    #define GONBEST_INIT_HEIGHT_OFFSET(uv,viewDir) half2 __offset = GBParallaxOffset(tex2D(_HeightMap,uv).y,_Height,viewDir);
    //应用高度图的偏移
    #define GONBSET_HEIGHT_OFFSET_APPLY(uv) uv += __offset;
#else
    #define GONBEST_INIT_HEIGHT_OFFSET(uv,viewDir)
    #define GONBSET_HEIGHT_OFFSET_APPLY(uv)
#endif

#endif //GONBEST_HEIGHTMAP_CG_INCLUDED