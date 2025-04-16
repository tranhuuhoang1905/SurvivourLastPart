/*
Author:gzg
Date:2019-08-20
Desc:根据电磁波理论推导出来的模型，反映了各向异性表面的反射和折射,
     头发的高光公式	 
*/

#ifndef GONBEST_KAJIYAKAY_CG_INCLUDED
#define GONBEST_KAJIYAKAY_CG_INCLUDED
#include "../Base/CommonCG.cginc"
#include "../Base/MathCG.cginc"

/*===================================SpecularTerm==============================================*/
//根据电磁波理论推导出来的模型，反映了各向异性表面的反射和折射。
//标准高光kajiyakay 头发
inline float GBKajiyaKey(float3 T, float3 H, float exponent)
{
	float dotTH = dot(T, H);
	float sinTH = sqrt(1.0 - dotTH*dotTH);
	//dirAtten值是通过方向控制Kajiya-Kay 着色模型中可见高光范围的衰减系数，即通过切线向量T和Half向量H的夹角的角度的不同，控制所得的高光能量值。
	//关于dirAtten的解释:知乎https://www.zhihu.com/question/36946353
	float dirAtten = smoothstep(-1.0, 0.0, dotTH);
	return dirAtten * pow(sinTH, exponent);
}

//kajiya - kay 算法 头发
//
/*
N:法线
TorB: 理论上是使用切线,但也可以使用次法线
H:半角向量
primaryShift:主偏移值
secondaryShift:次偏移值
specularPower1:主高光值
specularPower2:次高光值
*/
inline float2 GBKajiyaKaySpecularTerm(in float3 N, in float3 TorB,in float3 H ,in float primaryShift,in float secondaryShift, in float specularPower1,in float specularPower2)
{
	//对切线方向进行偏移
	float3 tangent1 = GBNormalizeSafe(TorB + primaryShift * N);
	float3 tangent2 = GBNormalizeSafe(TorB + secondaryShift * N);
	
	float2 spec = float2(GBKajiyaKey(tangent1 , H , specularPower1), GBKajiyaKey(tangent2 , H , specularPower2));
	
	return saturate(spec);
}

#endif //GONBEST_KAJIYAKAY_CG_INCLUDED