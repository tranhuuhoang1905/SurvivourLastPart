/*
Author:gzg
Date:2019-08-20
Desc:Beckmann贝克曼的动态分布函数,以及遮挡函数
*/
#ifndef GONBEST_BECKMANN_CG_INCLUDED
#define GONBEST_BECKMANN_CG_INCLUDED
#include "../Base/CommonCG.cginc"
#include "../Base/MathCG.cginc"
#include "SmithSchlickCG.cginc"

/*=============================D=========================================*/
//DBeckmann(m)=(1/(π * pow(α,2) pow((n.m),4))) * exp((pow((n?m),2)-1)/pow(α,2)pow((n.m),2))
inline half GBBeckmannNDFTerm(half nh,half roughness)
{
    half a = roughness * roughness;
    half a2 = a * a;
    half d1 = a2 * GBPow4(nh) ;
    d1 = GONBEST_INV_PI / d1;
    half d2 = (nh*nh -1)/(a2 * nh * nh);
    d2 = exp(d2);
    return d1 * d2;    
}

/*=============================V=========================================*/
// Smith-Schlick derived for Beckmann
inline half GBBeckmannGBSmithVisibilityTerm (half NdotL, half NdotV, half roughness)
{
    half c = 0.797884560802865h; // c = sqrt(2 / Pi)
    half k = roughness * c;
    return GBSmithVisibilityTerm (NdotL, NdotV, k) * 0.25f; // * 0.25 is the 1/4 of the visibility term
}

#endif //GONBEST_BECKMANN_CG_INCLUDED