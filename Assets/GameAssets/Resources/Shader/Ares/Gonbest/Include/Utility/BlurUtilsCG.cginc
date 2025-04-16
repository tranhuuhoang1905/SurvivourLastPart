/*
Author:gzg
Date:2019-08-20
Desc:模糊化效果的处理
*/

#ifndef GONBEST_BLURUTILS_CG_INCLUDED
#define GONBEST_BLURUTILS_CG_INCLUDED

//获得径向模糊的偏移值
inline half2 RadialBlurOffset(half2 uv, half2 center,half2 blurStrength)
{
    return blurStrength * (center - uv);
}

//径向模糊采样处理
inline float4 RadialBlurSample(sampler2D tex,half2 uv,half2 blurOffset)
{
    float4 color = tex2D(tex, uv);
    uv += blurOffset;
    color = tex2D(tex, uv);
    uv += blurOffset;
    color = tex2D(tex, uv);
    uv += blurOffset;
    color = tex2D(tex, uv);
    uv += blurOffset;
    color = tex2D(tex, uv);
    uv += blurOffset;
    color = tex2D(tex, uv);
    uv += blurOffset;
    return  color / 6;
}


//获得高斯模糊的偏移值
inline half2 GaussianBlurOffset(half2 texSize, half2 offsetDir, half blurSize)
{
    return texSize * offsetDir * blurSize;
}

//高斯模糊采样处理
inline float4 GaussianBlurSampler(sampler2D tex,half2 uv,half2 blurOffset)
{
    //static const half weights[7] = { 0.0205, 0.0855, 0.232, 0.324, 0.232, 0.0855, 0.0205 };
    half2 coords = uv - blurOffset * 3.0;
    fixed4 color = 0;
    color += tex2D(_MainTex, coords) * 0.0205;
    coords += blurOffset;
    
    color += tex2D(_MainTex, coords) *  0.0855;
    coords += blurOffset;
    
    color += tex2D(_MainTex, coords) *0.232;
    coords += blurOffset;
    
    color += tex2D(_MainTex, coords) * 0.324;
    coords += blurOffset;
    
    color += tex2D(_MainTex, coords) *  0.232;
    coords += blurOffset;
    
    color += tex2D(_MainTex, coords) * 0.0855;
    coords += blurOffset;
    
    color += tex2D(_MainTex, coords) * 0.0205;

    return color;
}

#endif