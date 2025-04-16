/*
Author:gzg
Date:2019-08-20
Desc:丝绒模型的漫反射计算公式
*/
#ifndef GONBEST_MINNAERT_CG_INCLUDED
#define GONBEST_MINNAERT_CG_INCLUDED
#include "../Base/CommonCG.cginc"

/*
Minnaert 漫反射模型  丝绒 反射公式
*/
inline half MinnaertDiffuse(half nl,half nv, half Darken)
{
    return saturate(nl)* pow(nl*nv, Darken);
}
#endif //GONBEST_MINNAERT_CG_INCLUDED