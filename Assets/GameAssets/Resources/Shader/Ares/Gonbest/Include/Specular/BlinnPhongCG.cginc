/*
Author:gzg
Date:2019-08-20
Desc:BlinnPhong的高光公式
*/
#ifndef GONBEST_BLINNPHONG_CG_INCLUDED
#define GONBEST_BLINNPHONG_CG_INCLUDED
#include "../Base/CommonCG.cginc"

/*=============================D=========================================*/
//BlinnPhong的正态分布函数
inline half GBGBBlinnPhongNDFTermOptimize(half NdotH, half n)
{
    // norm = (n+2)/(2*pi)
    half normTerm = (n + 2.0) * GONBEST_INV_TWO_PI;//(0.5/UNITY_PI);

    half specTerm = pow (NdotH, n);
    return specTerm * normTerm;
}

//BlinnPhong的原始公式--没有优化
inline half GBBlinnPhongNDFTerm(half NdotH, half roughness)
{
    half a = roughness * roughness;
    half a2 = a * a;
    half rcp_a2 = 1/a2;
    return rcp_a2 * GONBEST_INV_PI * pow(NdotH , 2*(rcp_a2 - 1));
}

//球形高斯来近似处理(approximated with a Spherical Gaussian)
//pow(x,n) == exp((n + 0.775) * (x - 1));

/*=============================V = 1=========================================*/


#endif //GONBEST_BLINNPHONG_CG_INCLUDED