/*
Author:gzg
Date:2019-08-20
Desc:通用的Smith-Schlick V公式
*/

#ifndef GONBEST_SMITHSCHLICK_CG_INCLUDED
#define GONBEST_SMITHSCHLICK_CG_INCLUDED
#include "../Base/CommonCG.cginc"

/*通用的Smith-Schlick V公式*/

/*=============================D=========================================*/

/*=============================V=========================================*/
//通用的Smith-Schlick V公式
// Generic Smith-Schlick visibility term
inline half GBSmithVisibilityTerm (half NdotL, half NdotV, half k)
{
    half gL = NdotL * (1-k) + k;
    half gV = NdotV * (1-k) + k;
    return 1.0 / (gL * gV + 1e-5f); // This function is not intended to be running on Mobile,
                                    // therefore epsilon is smaller than can be represented by half
}

#endif //GONBEST_SMITHSCHLICK_CG_INCLUDED