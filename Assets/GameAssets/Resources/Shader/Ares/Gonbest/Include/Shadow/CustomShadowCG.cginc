/*======================================================================
Author:gzg
Date:2019-08-20
Desc:自定义的阴影处理,采样通过程序生成的shadowmap,然后进行投影处理.
======================================================================*/

#ifndef GONBEST_CUSTOMSHADOWCG_CG_INCLUDED
#define GONBEST_CUSTOMSHADOWCG_CG_INCLUDED

#include "../Base/MathCG.cginc"
#include "./ShadowFunctionCG.cginc"

/*******************ShadowMap阴影处理****************************/
#if defined(_GONBEST_CUSTOM_SHADOW_ON)
    //角色的引用贴图
	uniform sampler2D	_MyShadowMap;			//生成的阴影图
	uniform float4 		_MyShadowMap_TexelSize;
	uniform float4x4	_MyWorld2ShadowProj;  //投影空间与世界空间的转换矩阵
	uniform fixed		_ShadowIntensity;	  //阴影强度
	uniform fixed       _ShadowFadeFactor;    //阴影被材质影响消隐的效果
	uniform float       _ShadowDepthBias;     //深度Bias
	
	

	//获取阴影的值--没有深度信息,只是通过颜色渲染
	inline float GetShadowValueByColor(sampler2D shadowMap,float4 sppos,float intensity,float fadeFactor)
	{
		float2 uv = CalcTexcoord(sppos);		
		float shadow = 1 - tex2D(shadowMap, uv).x;	
		shadow = shadow * ShadowRange(uv);
		float value = lerp(1,intensity,shadow);
		return saturate(value+fadeFactor);
	}

	//获取阴影的值 -- 这个有深度对比,不做自阴影
	inline float GetShadowValueBySimple(sampler2D shadowMap,float4 sppos,float intensity,float fadeFactor)
	{		
		float2 uv = CalcTexcoord(sppos);		
		float depth = CalcDepth(sppos);	
	    float ld = tex2D(shadowMap, uv).x;
		float shadow = step(ld,depth) *ShadowRange(uv);
		float value = lerp(1,intensity, shadow);
		return saturate(value+fadeFactor);
	}

	//获取阴影的值 -- 这个有深度对比,不做自阴影
	inline float GetShadowValueByPCF(sampler2D shadowMap,float4 sppos,float intensity,float fadeFactor)
	{		
		float2 uv = CalcTexcoord(sppos);		
		float depth = CalcDepth(sppos);	
	    float shadow = PCF_3X3(shadowMap,_MyShadowMap_TexelSize.xy,uv,depth);	
		shadow = shadow * ShadowRange(uv);
		float value = lerp(1,intensity, shadow);
		return saturate(value+fadeFactor);
	}


	//获取阴影的值 -- 这个有深度对比,可以做自身阴影
	inline float GetShadowValueDepth(sampler2D shadowMap,float4 texelSize,float4 sppos,float intensity,float fadeFactor,float bias)
	{		
		float2 uv = CalcTexcoord(sppos);		
		float depth = CalcDepth(sppos) + bias;
		float shadow = PCF_4X4(shadowMap,texelSize.xy,uv,depth);		
		shadow = shadow * ShadowRange(uv);
		float value = lerp(1, intensity, shadow);
		return saturate(value+fadeFactor);
	}

  //切比雪夫不等式
	inline float Chebyshev(float2 moments,float d)
	{
		//表面是完全亮的。因为当前片段是在光遮挡器之前  
		//if (d <= (moments.x-0.001))
		//	return 1.0;
		//碎片在阴影或半影中。 我们现在用切比雪夫的上界来检查 这个像素被点亮的可能性(p_max)  
		float variance = moments.y - (moments.x * moments.x);
		//variance = max(variance, 0.000002);
		variance = max(variance, 0.00002);
		float d_minus_mean = d - moments.x;
		float p_max = variance / (variance + d_minus_mean * d_minus_mean);
		return p_max;
	}

	//获取阴影的值 -- 这个有深度对比,可以做自身阴影
	inline float GetShadowValueByVSM(sampler2D shadowMap,float4 sppos,float intensity,float fadeFactor)
	{		
		float2 uv = CalcTexcoord(sppos);		
		float depth = CalcDepth(sppos);
	    float2 moments = tex2D(shadowMap, uv).rg;
		float shadow = Chebyshev(moments,depth) * ShadowRange(uv);
		float value = lerp(1,intensity, shadow);
		return saturate(value+fadeFactor);
	}
	
	//定义阴影投影的坐标寄存器
	#define GONBEST_CUSTOM_SHADOW_COORDS(idx1) float4 _shadowCoord : TEXCOORD##idx1;
	
	//对投影坐标进行转换 -- 这里针对Unity的UV开始信息做一些处理 --> i:vert的输入(vertex),o:vert的输出	
	#define GONBEST_CUSTOM_TRANSFER_SHADOW_WPOS(o,wpos) o._shadowCoord = mul(_MyWorld2ShadowProj,wpos);

	#define GONBEST_CUSTOM_TRANSFER_SHADOW(i,o) o._shadowCoord = mul(_MyWorld2ShadowProj,mul(unity_ObjectToWorld,i.vertex));

	//应用阴影值-->i:frag的输入,color:颜色输入输出
	#define GONBEST_CUSTOM_APPLY_SHADOW(i,fcolor) fcolor.rgb *= GetShadowValueByColor(_MyShadowMap,i._shadowCoord,_ShadowIntensity,_ShadowFadeFactor);

	#define GONBEST_CUSTOM_DECODE_SHADOW_VALUE(i) GetShadowValueByColor(_MyShadowMap, i._shadowCoord, _ShadowIntensity, _ShadowFadeFactor)

	#define GONBEST_CUSTOM_DECODE_SHADOW_VALUE_DEPTH(i) GetShadowValueDepth(_MyShadowMap,_MyShadowMap_TexelSize,i._shadowCoord, _ShadowIntensity, _ShadowFadeFactor,_ShadowDepthBias)

#else //默认使用Unity的Shader
    #define GONBEST_CUSTOM_SHADOW_COORDS(idx1) 
	#define GONBEST_CUSTOM_TRANSFER_SHADOW_WPOS(o,wpos)
	#define GONBEST_CUSTOM_TRANSFER_SHADOW(i,o)
	#define GONBEST_CUSTOM_DECODE_SHADOW_VALUE(i)	1
	#define GONBEST_CUSTOM_APPLY_SHADOW(i,fcolor)  
	#define GONBEST_CUSTOM_DECODE_SHADOW_VALUE_DEPTH(i) 1
#endif

#endif //GONBEST_CUSTOMSHADOWCG_CG_INCLUDED