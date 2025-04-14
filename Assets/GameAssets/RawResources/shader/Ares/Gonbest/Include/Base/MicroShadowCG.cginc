/*=============================================================
Author:gzg
Date:2019-08-20
Desc:微表面阴影的计算
     Ambient Occlusion环境光遮挡处理
=============================================================*/
#ifndef GONBEST_MICROSHADOW_CG_INCLUDED
#define GONBEST_MICROSHADOW_CG_INCLUDED
#include "MathCG.cginc"

//获取AO
inline half GBOcclusion(sampler2D aomap,float2 uv,float strength)
{
    #if (SHADER_TARGET < 30)
        // SM20: instruction count limitation
        // SM20: simpler occlusion
        return tex2D(aomap, uv).g;
    #else
        half occ = tex2D(aomap, uv).g;
        return GBLerpOneTo (occ, strength);
    #endif
}


/*
nl:dot(N,L)
ao:环境遮挡的系数
*/
inline float MicroShadowTerm(float nl, float ao)
{
    return abs(nl) + 2*ao*ao - 1;
}


#ifdef _GONBEST_AO_MAP
    //遮挡map
    uniform sampler2D _OcclusionMap;
    //遮挡强度
    uniform float _OcclusionStrength;

    #define GONBEST_GET_AO_VALUE(uv) GBOcclusion(_OcclusionMap,uv,_OcclusionStrength)
#else
    #define GONBEST_GET_AO_VALUE(uv) 1
#endif
	
#endif //GONBEST_MICROSHADOW_CG_INCLUDED