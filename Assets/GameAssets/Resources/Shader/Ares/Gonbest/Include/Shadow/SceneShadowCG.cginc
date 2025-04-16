/*======================================================================
Author:gzg
Date:2019-08-20
Desc:自定义的阴影处理,采样通过程序生成的shadowmap,然后进行投影处理.
======================================================================*/

#ifndef GONBEST_SCENCESHADOWCG_CG_INCLUDED
#define GONBEST_SCENCESHADOWCG_CG_INCLUDED

#include "../Base/MathCG.cginc"
#include "./ShadowFunctionCG.cginc"

/*******************ShadowMap阴影处理****************************/
#if defined(_GONBEST_CUSTOM_SHADOW_ON)
	//场景的阴影贴图
	uniform sampler2D	_SceneShadowMap;			//生成的阴影图
	uniform float4 		_SceneShadowMap_TexelSize;
	uniform float4x4	_SceneWorld2ShadowProj;  //投影空间与世界空间的转换矩阵
	uniform fixed		_SceneShadowIntensity;	  //阴影强度

	//获取阴影的值--没有深度信息,只是通过颜色渲染
	inline float3 GetSceneShadowValue(sampler2D shadowMap,float4 sppos,float intensity,float3 fcolor)
	{
		float2 uv = CalcTexcoord(sppos);        		
		float shadow = 1 - tex2D(shadowMap, uv).x;
		shadow = shadow * ShadowRange(uv);
		float3 value = lerp(fcolor, UNITY_LIGHTMODEL_AMBIENT.xyz, shadow);
		return value;
	}
	
	inline float3 GetSceneShadowValueBySimple(sampler2D shadowMap,float4 sppos,float intensity,float3 fcolor)
	{		
		float2 uv = CalcTexcoord(sppos);
		float depth = CalcDepth(sppos);	
	    float ld = tex2D(shadowMap, uv).x;
		float shadow = step(ld,depth) * ShadowRange(uv);
		float3 value = lerp(fcolor, UNITY_LIGHTMODEL_AMBIENT.xyz, shadow);
		return value;
	}


	//定义阴影投影的坐标寄存器
	#define GONBEST_SCENCE_SHADOW_COORDS(idx1) float4 _sceneShadowCoord : TEXCOORD##idx1;
	
	//对投影坐标进行转换 -- 这里针对Unity的UV开始信息做一些处理 --> i:vert的输入(vertex),o:vert的输出	
	#define GONBEST_SCENCE_TRANSFER_SHADOW_WPOS(o,wpos) o._sceneShadowCoord = mul(_SceneWorld2ShadowProj,wpos);

	#define GONBEST_SCENCE_TRANSFER_SHADOW(i,o) o._sceneShadowCoord = mul(_SceneWorld2ShadowProj,mul(unity_ObjectToWorld,i.vertex));

	//应用阴影值-->i:frag的输入,color:颜色输入输出
	#define GONBEST_SCENCE_APPLY_SHADOW(i,fcolor) fcolor = GetSceneShadowValue(_SceneShadowMap,i._sceneShadowCoord,_SceneShadowIntensity,fcolor);

#else //默认使用Unity的Shader
    #define GONBEST_SCENCE_SHADOW_COORDS(idx1) 
	#define GONBEST_SCENCE_TRANSFER_SHADOW_WPOS(o,wpos)
	#define GONBEST_SCENCE_TRANSFER_SHADOW(i,o)	
	#define GONBEST_SCENCE_APPLY_SHADOW(i,fcolor)  
#endif

#endif //GONBEST_SCENCESHADOWCG_CG_INCLUDED