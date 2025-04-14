/*=============================================================
Author:gzg
Date:2019-08-20
Desc:这里存储各种hash算法(随机算法),以及与hash算法密切相关的噪音算法
=============================================================*/
#ifndef GONBEST_HASH_NOSIE_CG_INCLUDED
#define GONBEST_HASH_NOSIE_CG_INCLUDED



//求hash
float GBHash1(in float2 p)
{
    return frac( sin( dot(p, float2(127.1, 311.7)) ) * 43758.5453 );
}

//随机算法
//举个例子: n = uv * 1024 + frac(Time.y);
float GBHash2(float2 n) 
{                
    return frac(sin(dot(n.xy, float2(12.9898, 78.233)))* 43758.5453);
}

//制作噪音
float GBNoise1(in float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    
    //Hermite(艾米插值)插值算法
    float2 u= f * f * (3.0 - 2.0*f );
    
    return -1.0 + 2.0 * lerp(
                    lerp(GBHash1(i + float2(0.0,0.0)), GBHash1(i+float2(1.0,0.0)), u.x),
                    lerp(GBHash1(i + float2(0.0,1.0)), GBHash1(i+float2(1.0,1.0)), u.x),
                    u.y);
}

#endif //GONBEST_HASH_NOSIE_CG_INCLUDED