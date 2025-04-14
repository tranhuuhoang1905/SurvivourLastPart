/*=============================================================
Author:gzg
Date:2019-08-20
Desc:实现的一些基础数学函数
=============================================================*/

#ifndef GONBEST_MATH_CG_INCLUDED
#define GONBEST_MATH_CG_INCLUDED
#include "CommonCG.cginc"

//pow4的系列函数
inline float GBPow4 (float x)
{
    return x*x*x*x;
}

inline float2 GBPow4 (float2 x)
{
    return x*x*x*x;
}

inline float3 GBPow4 (float3 x)
{
    return x*x*x*x;
}

inline float4 GBPow4 (float4 x)
{
    return x*x*x*x;
}

// Pow5 uses the same amount of instructions as generic pow(), but has 2 advantages:
// 1) better instruction pipelining
// 2) no need to worry about NaNs
inline half GBPow5 (half x)
{
    return x*x * x*x * x;
}



inline half2 GBPow5 (half2 x)
{
    return x*x * x*x * x;
}

inline half3 GBPow5 (half3 x)
{
    return x*x * x*x * x;
}

inline half4 GBPow5 (half4 x)
{
    return x*x * x*x * x;
}

//返回(1-x)^5的值,在[0,1]的近似函数
inline float GBPow5OneMinusXWith01(half x)
{
    return exp2((-5.55473*x - 6.98316)*x);   
}

//线性插值
inline float GBLinearstep(float a, float b, float x)
{
    return saturate((x - a)/(b - a));
}
//仿smoothstep函数
// <a return 0
// >b return 1
// x <= b && x >= a return [0,1]
inline float GBSmoothstep(float a, float b, float x)
{
    float t = saturate((x - a)/(b - a));   
    //Hermite(艾米插值)插值算法
    return t*t*(3.0 - 2.0*t);
}

//线性插值
half GBLerpOneTo(half b, half t)
{
    half oneMinusT = 1 - t;
    return oneMinusT + b * t;
}

//旋转,其中rot是(sin(angle),cos(angle))
inline float2 GBRotate( float2 v, float2 rot) 
{
    float2 ret;
    ret.x = v.x * rot.y - v.y * rot.x;
    ret.y = v.x * rot.x + v.y * rot.y;
    return ret;
}

//通过角度旋转,
//angle = frac(_Time.x * speed) * GONBEST_TWO_PI 
inline float2 GBRotateByAngle( float2 v, float angle ) 
{
    float2 rot;
    sincos(angle, rot.x, rot.y);
    return GBRotate(v,rot);
}


//使用这个进行归一化,为了处理在iphone上异常的问题
//安全的归一化处理
inline float2 GBNormalizeSafe(float2 v)
{
    float d = dot(v,v);
    d = sqrt(d) + GONBEST_EPSILON;
    return v/d;
}

//安全的归一化处理
inline float3 GBNormalizeSafe(float3 v)
{
    float d = dot(v,v);
    d = sqrt(d) + GONBEST_EPSILON;
    return v/d;
}

//安全的归一化处理
inline float4 GBNormalizeSafe(float4 v)
{
    float d = dot(v,v);
    d = sqrt(d) + GONBEST_EPSILON;
    return v/d;
}

#endif //GONBEST_MATH_CG_INCLUDED