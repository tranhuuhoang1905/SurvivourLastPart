/*===============================================================
Author:gzg
Date:2019-08-20
Desc:各种菲涅尔公式的实现
=================================================================*/

#ifndef GONBEST_FRESNEL_CG_INCLUDED
#define GONBEST_FRESNEL_CG_INCLUDED
#include "MathCG.cginc"

//标准公式
inline half3 GBFresnelTerm (half3 F0, half cosA)
{
    half t = GBPow5(1-cosA);
    return F0 + (1-F0) * t;
}

//差值
inline half3 GBFresnelLerp (half3 F0, half3 F90, half cosA)
{
    half t = GBPow5(1-cosA);
    return lerp (F0, F90, t);
}

//标准公式快速
inline half3 GBFresnelTermFast (half3 F0, half cosA)
{
    half t = GBPow5OneMinusXWith01(1-cosA);
    return F0 + (1-F0) * t;
}

//差值公式快速
inline half3 GBFresnelLerpFast (half3 F0, half3 F90, half cosA)
{
    half t = GBPow5OneMinusXWith01 (cosA);
    return lerp (F0, F90, t);
}

//经验公式,使用高亮颜色的绿色通道作为F90
inline half3 GBFresnelTermFastWithSpecGreen (half3 F0,half cosA)
{
    half t = GBPow5OneMinusXWith01 (cosA);
    half3 F90 = saturate(F0.y * 50);
    return lerp (F0, F90, t);
}



#endif //GONBEST_FRESNEL_CG_INCLUDED