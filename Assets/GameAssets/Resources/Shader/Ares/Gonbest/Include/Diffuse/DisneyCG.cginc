
/*
Author:gzg
Date:2019-08-20
Desc:迪斯尼的漫反射计算公式
*/

#ifndef GONBEST_DISNEY_CG_INCLUDED
#define GONBEST_DISNEY_CG_INCLUDED
#include "../Base/MathCG.cginc"

/*
迪斯尼漫反射在函数外必须乘以 diffuseAlbedo / PI

perceptualRoughness:感知的粗糙度 1-Smoothness
*/
// Note: Disney diffuse must be multiply by diffuseAlbedo / PI. This is done outside of this function.
half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
{
    half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
    // Two schlick fresnel term
    half lightScatter   = (1 + (fd90 - 1) * GBPow5(1 - NdotL));
    half viewScatter    = (1 + (fd90 - 1) * GBPow5(1 - NdotV));

    return lightScatter * viewScatter * GONBEST_INV_PI;
}

#endif //GONBEST_DISNEY_CG_INCLUDED