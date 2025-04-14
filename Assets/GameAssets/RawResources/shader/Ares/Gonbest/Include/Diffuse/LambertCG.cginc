
/*
Author:gzg
Date:2019-08-20
Desc:lambertian兰伯特模型的漫反射计算公式
*/
#ifndef GONBEST_LAMBERT_CG_INCLUDED
#define GONBEST_LAMBERT_CG_INCLUDED
#include "../Base/CommonCG.cginc"

//lambertian兰伯特模型
inline half LambertDiffuse(half nl)
{
    return max(0,nl);
}

//半兰伯特模型
inline half HalfLambertDiffuse(half nl)
{
    return max(0,nl) * 0.5 + 0.5;
}

#endif //GONBEST_LAMBERT_CG_INCLUDED