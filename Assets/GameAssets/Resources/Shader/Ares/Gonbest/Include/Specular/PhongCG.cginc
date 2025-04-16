/*
Author:gzg
Date:2019-08-20
Desc:Phong的高光公式
     就是光线通过法线反射后的方向R与视线方向V夹角越小,那么这个像素点就会越亮.
     同理,视线通过法线反射后的方向R与光源到交点的方向L之间的夹角越小,那么这个像素点就会越亮.
*/

#ifndef GONBEST_PHONG_CG_INCLUDED
#define GONBEST_PHONG_CG_INCLUDED
#include "../Base/CommonCG.cginc"

//R:是反射reflect(-V,N) 需要注意的是：reflect 函数的视线方向是由摄像机指向交点的，所以这里的参数要取负
//这个函数应该会比较常用,因为这里的R值,可以用到texCube的采样.
half GBPhongSpecularTerm1(float3 R ,float3 L, half gloss)
{    
    return pow(max(0,dot(R,L)),gloss);
}


//R:是反射reflect(-L,N) 需要注意的是：reflect 函数的入射方向是由光源指向交点的，所以这里的参数要取负
half GBPhongSpecularTerm2(float3 R ,float3 V, half gloss)
{    
    return pow(max(0,dot(R,V)),gloss);
}


#endif //GONBEST_PHONG_CG_INCLUDED