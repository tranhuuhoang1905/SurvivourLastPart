/*======================================================================
Author:gzg
Date:2019-08-20
Desc:自定义的阴影处理,采样通过程序生成的shadowmap,然后进行投影处理.
======================================================================*/

#ifndef GONBEST_SHADOWFUNCTION_CG_INCLUDED
#define GONBEST_SHADOWFUNCTION_CG_INCLUDED

#include "../Base/MathCG.cginc"

/*******************ShadowMap阴影处理****************************/

	//阴影的范围
    inline float ShadowRange(float2 uv)
	{
		uv = uv *2 -1;
		float d = dot(uv,uv);
        d = saturate((1-d)*5); 
		return d;
	}

	//计算Shadowmap的采样uv值,并把采样点的起始位置,调整到左下角.
    inline float2 CalcTexcoord(float4 lvpPos)
	{
		float2 uv = lvpPos.xy/lvpPos.w * 0.5 + 0.5;
		#if UNITY_UV_STARTS_AT_TOP
		  	uv.y = 1 - uv.y;
		#endif
		return uv;
	}

	//计算深度的值,把深度值转换到HDC[0,1]的区间,然后规则深度排序Near:0->Far:1
	inline float CalcDepth(float4 lvpPos)
	{
		float depth = 0;
		if(UNITY_NEAR_CLIP_VALUE < 0)
		{
			depth = lvpPos.z / lvpPos.w * 0.5 + 0.5;
		}
		else
		{
			depth = lvpPos.z / lvpPos.w;
		}

		#if UNITY_REVERSED_Z
			depth = 1 - depth;
		#endif 
		return depth;
	}

	//把深度进行编码
	inline float4 EncodeDepth(float depth)
	{
		return EncodeFloatRGBA(depth);
	}

	//解码深度
	inline float DecodeDepth(float4 rgba)
	{
		return DecodeFloatRGBA(rgba);
	}

	//计算遮挡
	inline float4 CalculateOcclusion(float4 ShadowmapDepth,float4 SceneDepth)
	{
		//精度
		//float TransitionScale = 8000;
		return saturate(1 - (SceneDepth - ShadowmapDepth) * 8000 );
	}

	//纹理采样之后进行比较最后获得bool值0,1
	inline float Tex2DComparison(sampler2D shadowMap,float2 uv,float litz)
	{		 
		 return step(DecodeDepth(tex2D(shadowMap, uv)), litz);
	}

	inline float PCF_4X4(sampler2D shadowMap,float2 shadowMapSize, float2 uv,float litz)
	{
		litz = litz + 0.0005;
		float2 texelPos = (uv /shadowMapSize);	
		float2 texelCenter = (texelPos - float2(1.5, 1.5));
		float shadow = 0;		
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(0.0, 0.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(1.0, 0.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(2.0, 0.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(3.0, 0.0)) * shadowMapSize,litz);

		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(0.0, 1.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(1.0, 1.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(2.0, 1.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(3.0, 1.0)) * shadowMapSize,litz);

		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(0.0, 2.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(1.0, 2.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(2.0, 2.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(3.0, 2.0)) * shadowMapSize,litz);

		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(0.0, 3.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(1.0, 3.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(2.0, 3.0)) * shadowMapSize,litz);
		shadow = shadow + Tex2DComparison(shadowMap,(texelCenter + float2(3.0, 3.0)) * shadowMapSize,litz);
		
		return shadow * 0.0625;
	}	

	float PCF_3X3(sampler2D shadowMap,float2 shadowMapSize, float2 uv,float litz)
	{
		float2 TexelPos = uv/shadowMapSize - 0.5;
		float2 Fraction = frac(TexelPos);
		float2 TexelCenter = floor(TexelPos) + 0.5;
		TexelCenter = TexelCenter - float2(1,1);

		float4 Values0;
		float4 Values1;
		float4 Values2;
		float4 Values3;

		Values0.x=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(0,0))*shadowMapSize ));
		Values0.y=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(1,0))*shadowMapSize )); 
		Values0.z=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(2,0))*shadowMapSize ));
		Values0.w=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(3,0))*shadowMapSize ));
		Values0=CalculateOcclusion(Values0,litz.xxxx);

		Values1.x=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(0,1))*shadowMapSize ));
		Values1.y=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(1,1))*shadowMapSize ));
		Values1.z=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(2,1))*shadowMapSize ));
		Values1.w=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(3,1))*shadowMapSize ));
		Values1=CalculateOcclusion(Values1,litz.xxxx);

		Values2.x=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(0,2))*shadowMapSize ));
		Values2.y=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(1,2))*shadowMapSize ));
		Values2.z=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(2,2))*shadowMapSize ));
		Values2.w=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(3,2))*shadowMapSize ));
		Values2=CalculateOcclusion(Values2,litz.xxxx);

		Values3.x=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(0,3))*shadowMapSize ));
		Values3.y=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(1,3))*shadowMapSize ));
		Values3.z=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(2,3))*shadowMapSize ));
		Values3.w=DecodeDepth(tex2D(shadowMap,(TexelCenter + float2(3,3))*shadowMapSize ));
		Values3=CalculateOcclusion(Values3,litz.xxxx);
		
		
		float inShadow = 0;
		//v0~v1
		float2 VerticalLerp00=lerp(float2(Values0.x,Values1.x),float2(Values0.y,Values1.y),Fraction.xx); 
		inShadow = inShadow + lerp(VerticalLerp00.x,VerticalLerp00.y,Fraction.y);

		float2 VerticalLerp10=lerp(float2(Values0.y,Values1.y),float2(Values0.z,Values1.z),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp10.x,VerticalLerp10.y,Fraction.y);

		float2 VerticalLerp20=lerp(float2(Values0.z,Values1.z),float2(Values0.w,Values1.w),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp20.x,VerticalLerp20.y,Fraction.y);


        //v1~v2 
		float2 VerticalLerp01=lerp(float2(Values1.x,Values2.x),float2(Values1.y,Values2.y),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp01.x,VerticalLerp01.y,Fraction.y);

		float2 VerticalLerp11=lerp(float2(Values1.y,Values2.y),float2(Values1.z,Values2.z),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp11.x,VerticalLerp11.y,Fraction.y);

		float2 VerticalLerp21=lerp(float2(Values1.z,Values2.z),float2(Values1.w,Values2.w),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp21.x,VerticalLerp21.y,Fraction.y);


		//v2~v3
		float2 VerticalLerp02=lerp(float2(Values2.x,Values3.x),float2(Values2.y,Values3.y),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp02.x,VerticalLerp02.y,Fraction.y);

		float2 VerticalLerp12=lerp(float2(Values2.y,Values3.y),float2(Values2.z,Values3.z),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp12.x,VerticalLerp12.y,Fraction.y);

		float2 VerticalLerp22=lerp(float2(Values2.z,Values3.z),float2(Values2.w,Values3.w),Fraction.xx);
		inShadow = inShadow + lerp(VerticalLerp22.x,VerticalLerp22.y,Fraction.y);

		inShadow = inShadow * 0.11111;//(1/9)
		return 1.0 - inShadow ;
	}

#endif //GONBEST_SHADOWFUNCTION_CG_INCLUDED