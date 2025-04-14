/*=============================================================
Author:gzg
Date:2019-08-20
Desc:粗糙度的处理,下面就是几个由光滑度转换为粗糙度的方法
	 其中特别注意的是:perceptual roughness 感知粗糙度 和 academic roughness 理论的粗糙度的区别
=============================================================*/

#ifndef GONBEST_ROUGHNESS_CG_INCLUDED
#define GONBEST_ROUGHNESS_CG_INCLUDED

//获得感觉的粗糙度 perceptual roughness
inline half GetPerceptualRoughness(in half Smoothness)
{
	return (1- Smoothness);
}

//获取理论的粗糙度 academic roughness
inline half GetRoughness(in half Smoothness)
{
    half oneMinusSmoothness = (1- Smoothness);
	return oneMinusSmoothness * oneMinusSmoothness;
}

//通过粗糙度获取计算Blinn高光的Power值
inline half GBGetSpecPower (in half Smoothness)
{
    half m = GetRoughness(Smoothness);   // m is the true academic roughness.
    half sq = max(1e-4f, m*m);
    half n = (2.0 / sq) - 2.0;                          // https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
    n = max(n, 1e-4f);                                  // prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
    return n;
}

//获取地形的粗糙度 -- 石板地表
inline half GetRoughness_Ground(in half Smoothness,in float3 N,in half envFactor)
{
	half rain = envFactor;
	rain = 1 - rain * saturate(N.y * 0.7 + 0.4 * rain);
	return rain * (1- Smoothness);
}

//获取皮肤的获取粗糙度的函数
inline half GetRoughness_Skin(in half Smoothness,in float3 N,in half envFactor)
{
    half Roughness = max(1-Smoothness,0.03);	 
	half rain= envFactor * 0.5;
	rain = 1 - rain* saturate(3*N.y + 0.2 + 0.1*rain);
	return clamp(rain * Roughness, 0.05, 1);
}

//获取头发的粗糙度
inline half GetRoughness_Hair(half Smoothness,float3 N,in half envFactor)
{
	half rain= envFactor * 0.5;
	rain = 1 - rain * saturate(3 * N.y + 0.2 + 0.1 * rain);
	return lerp(rain, 0.05, Smoothness);
}
#endif //GONBEST_ROUGHNESS_CG_INCLUDED