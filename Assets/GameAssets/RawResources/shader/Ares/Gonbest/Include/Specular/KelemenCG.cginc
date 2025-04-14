/*
Author:gzg
Date:2019-08-20
Desc:Kelemen克莱曼的高光处理.
*/

#ifndef GONBEST_KELEMEN_CG_INCLUDED
#define GONBEST_KELEMEN_CG_INCLUDED
#include "../Base/CommonCG.cginc"
#include "../Base/RoughnessCG.cginc"


/*=============================1/V==================================*/
//获取1/V
inline float GBKelemenINVVisibilityTerm(float lh, float smoothness)
{
    float roughness = GetRoughness(smoothness);
    return lh * lh * smoothness + roughness;
}
/*=============================1/F==================================*/
//获取1/F
inline float GBKelemenINVGBFresnelTerm(float lh)
{
    return lh;
}
/*=============================Specular Term==================================*/
inline half GBKelemenSpecularTerm(float nh,float lh, float smoothness)
{
    float sp = GBGetSpecPower(smoothness);
    float invV = GBKelemenINVVisibilityTerm(lh,smoothness);
    float invF = GBKelemenINVGBFresnelTerm(lh);
    half specularTerm = ((sp + 1) * pow (nh, sp)) / (8 * invV * invF + 1e-4h);

    #ifdef UNITY_COLORSPACE_GAMMA
        specularTerm = sqrt(max(1e-4f, specularTerm));
    #endif
    return specularTerm;
}



#endif //GONBEST_KELEMEN_CG_INCLUDED