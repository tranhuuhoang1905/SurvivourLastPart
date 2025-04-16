/*
Author:gzg
Date:2019-08-20
Desc:Ward 高光反射模型
    各向同性,各项异性。
*/

#ifndef GONBEST_WARD_CG_INCLUDED
#define GONBEST_WARD_CG_INCLUDED
#include "../Base/CommonCG.cginc"

/*===================================SpecularTerm==============================================*/
/*
H:半角向量
T:切线向量
B:次法线两项 cross(T,N)
nl:dot(N,L)
nh:dot(N,H)
nv:dot(N,V)
alphaX:Roughness in Brush Direction     //画刷方向的粗糙度,光在x方向大小
alphaY:Roughness orthogonal to Brush Direction //垂直于画刷方向的粗糙度 ,光在Y方向的大小
*/
inline float GBWardSpecularTerm(float3 H,float3 T,float B,float nl,float nh,float nv,float alphaX,float alphaY)
{
    float thx = dot(H,T) / alphaX;
    float bhy = dot(H,B) / alphaY;
    return sqrt(max(0,nl/nv)) * exp(-2.0 *(thx*thx+bhy*bhy)/(1.0+nh));
}
#endif //GONBEST_WARD_CG_INCLUDED