/*
Author:gzg
Date:2019-08-20
Desc:阴影处理的接口定义
*/

#ifndef GONBEST_SHADOWCG_CG_INCLUDED
#define GONBEST_SHADOWCG_CG_INCLUDED
#include "CustomShadowCG.cginc"
#include "UnityCG.cginc"
#include "AutoLight.cginc"

/*============================Shadow Receiver Helper========================================*/
#if defined(_GONBEST_SHADOW_ON)	
    
    #if defined(_GONBEST_CUSTOM_SHADOW_ON)
        //使用自定义的阴影接收器。

        //定义阴影投影的坐标寄存器
        #define GONBEST_SHADOW_COORDS(idx1) GONBEST_CUSTOM_SHADOW_COORDS(idx1)
        
        //对投影坐标进行转换 -- 这里针对Unity的UV开始信息做一些处理 --> i:vert的输入(vertex),o:vert的输出	
        #define GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,uv1) GONBEST_CUSTOM_TRANSFER_SHADOW_WPOS(o,wpos)

        #define GONBEST_TRANSFER_SHADOW(i,o,uv1) GONBEST_CUSTOM_TRANSFER_SHADOW(i,o)

        //应用阴影值-->i:frag的输入,color:颜色输入输出
        #define GONBEST_APPLY_SHADOW(i,wpos,fcolor) GONBEST_CUSTOM_APPLY_SHADOW(i,fcolor)

        #define GONBEST_DECODE_SHADOW_VALUE(i,wpos) GONBEST_CUSTOM_DECODE_SHADOW_VALUE(i)
        #define GONBEST_DECODE_SHADOW_VALUE_DEPTH(i,wpos) GONBEST_CUSTOM_DECODE_SHADOW_VALUE_DEPTH(i)

    #elif defined(_GONBEST_UNITY_SHADOW_ON)
        //使用Unity的阴影接受处理
        #if !defined(SHADOWS_SCREEN)
            #define SHADOWS_SCREEN 1
        #endif 
        //定义阴影投影的坐标寄存器
        #define GONBEST_SHADOW_COORDS(idx1) UNITY_SHADOW_COORDS(idx1)

        //对投影坐标进行转换 -- 这里针对Unity的UV开始信息做一些处理
        #define GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,uv1) UNITY_TRANSFER_SHADOW(o,uv1)

        #define GONBEST_TRANSFER_SHADOW(i,o,uv1) UNITY_TRANSFER_SHADOW(o,uv1)	

        //应用阴影值-->i:frag的输入,color:颜色输入输出
        #define GONBEST_APPLY_SHADOW(i,wpos,fcolor) fcolor.rgb *= UNITY_SHADOW_ATTENUATION(i,wpos);

        #define GONBEST_DECODE_SHADOW_VALUE(i,wpos)	UNITY_SHADOW_ATTENUATION(i,wpos)
        #define GONBEST_DECODE_SHADOW_VALUE_DEPTH(i,wpos) UNITY_SHADOW_ATTENUATION(i,wpos)
    #else    
        #define GONBEST_SHADOW_COORDS(idx1) 
	    #define GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,uv1)
	    #define GONBEST_TRANSFER_SHADOW(i,o,uv1)
	    #define GONBEST_DECODE_SHADOW_VALUE(i,wpos)	1
        #define GONBEST_DECODE_SHADOW_VALUE_DEPTH(i,wpos) 1
	    #define GONBEST_APPLY_SHADOW(i,wpos,fcolor)   
    #endif
#else //默认使用为空
    #define GONBEST_SHADOW_COORDS(idx1) 
	#define GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,uv1)
	#define GONBEST_TRANSFER_SHADOW(i,o,uv1)
	#define GONBEST_DECODE_SHADOW_VALUE(i,wpos)	1
    #define GONBEST_DECODE_SHADOW_VALUE_DEPTH(i,wpos) 1
	#define GONBEST_APPLY_SHADOW(i,wpos,fcolor)   

#endif

/*============================Shadow Caster Helper========================================*/
#if defined(_GONBEST_SHADOW_ON) && defined(_GONBEST_UNITY_SHADOW_ON)

    #if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
        // Rendering into point light (cubemap) shadows
        #define GONBEST_V2F_SHADOW_CASTER_NOPOS(idx) float3 vec : TEXCOORD#idx;
        //定义一个不带有Pos的寄存器
        #define GONBEST_SHADOW_CASTER_NOPOS_COORDS(idx) float3 vec : TEXCOORD#idx;
    #else
        // Rendering into directional or spot light shadows
        #define GONBEST_V2F_SHADOW_CASTER_NOPOS(idx)   
         //定义一个不带有Pos的寄存器
        #define GONBEST_SHADOW_CASTER_NOPOS_COORDS(idx)
    #endif    
   
    //定义一个带有pos的寄存器
    #define GONBEST_SHADOW_CASTER_COORDS(idx) GONBEST_V2F_SHADOW_CASTER_NOPOS(idx) UNITY_POSITION(pos)

    //定义不带Pos的顶点处理
    #define GONBEST_TRANSFER_SHADOW_CASTER_NOPOS(o,opos) TRANSFER_SHADOW_CASTER_NOPOS_LEGACY(o,opos)
    //定义不带Pos的顶点处理,这个里面需要处理法线v.normal
    #define GONBEST_TRANSFER_SHADOW_CASTER_NORMALOFFSET_NOPOS(o,opos) TRANSFER_SHADOW_CASTER_NOPOS(o,opos)

    //定义带有默认pos的顶点处理
    #define GONBEST_TRANSFER_SHADOW_CASTER(o) TRANSFER_SHADOW_CASTER_NOPOS_LEGACY(o,o.pos)
    //定义不带Pos的顶点处理,这个里面需要处理法线v.normal
    #define GONBEST_TRANSFER_SHADOW_CASTER_NORMALOFFSET(o) TRANSFER_SHADOW_CASTER_NOPOS(o,o.pos)    

    //在frag程序中,这个宏直接返回定义值
    #define GONBEST_SHADOW_CASTER_FRAGMENT(i) SHADOW_CASTER_FRAGMENT(i)
#else
//定义一个不带有Pos的寄存器
    #define GONBEST_SHADOW_CASTER_NOPOS_COORDS(idx)
    //定义一个带有pos的寄存器
    #define GONBEST_SHADOW_CASTER_COORDS(idx)

    //定义不带Pos的顶点处理
    #define GONBEST_TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
    //定义不带Pos的顶点处理,这个里面需要处理法线v.normal
    #define GONBEST_TRANSFER_SHADOW_CASTER_NORMALOFFSET_NOPOS(o,opos)

    //定义带有默认pos的顶点处理
    #define GONBEST_TRANSFER_SHADOW_CASTER(o)
    //定义不带Pos的顶点处理,这个里面需要处理法线v.normal
    #define GONBEST_TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

    //在frag程序中,这个宏直接返回定义值
    #define GONBEST_SHADOW_CASTER_FRAGMENT(i) return 0;
#endif

#endif