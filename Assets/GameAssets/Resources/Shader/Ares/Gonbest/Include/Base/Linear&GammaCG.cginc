/*=============================================================
Author:gzg
Date:2019-09-03
Desc:关于Linear和Gamma的相互转换的处理。
=============================================================*/
#ifndef GONBEST_LINEAR_GAMMA_CG_INCLUDED
#define GONBEST_LINEAR_GAMMA_CG_INCLUDED


//Gamma转Linear的标准公式
inline float GBGammaToLinearSpaceExact (float value)
{
    if (value <= 0.04045F)
        return value / 12.92F;
    else if (value < 1.0F)
        return pow((value + 0.055F)/1.055F, 2.4F);
    else
        return pow(value, 2.2F);
}

//Gamma转Linear的近似公式
inline half3 GBGammaToLinearSpace (half3 sRGB)
{
    // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

    // Precise version, useful for debugging.
    //return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
}

//Linear转Gamma的标准公式
inline float GBLinearToGammaSpaceExact (float value)
{
    if (value <= 0.0F)
        return 0.0F;
    else if (value <= 0.0031308F)
        return 12.92F * value;
    else if (value < 1.0F)
        return 1.055F * pow(value, 0.4166667F) - 0.055F;
    else
        return pow(value, 0.45454545F);
}
//Linear转Gamma的近似公式
inline half3 GBLinearToGammaSpace (half3 linRGB)
{
    linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
    // An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);

    // Exact version, useful for debugging.
    //return half3(LinearToGammaSpaceExact(linRGB.r), LinearToGammaSpaceExact(linRGB.g), LinearToGammaSpaceExact(linRGB.b));
}

//通过宏判断是否对颜色进行转换
#if defined(UNITY_COLORSPACE_GAMMA)
    #define GONBEST_LINEAR_TO_GAMMA(rgb) GBLinearToGammaSpace (rgb)
    #define GONBEST_GAMMA_TO_LINEAR(rgb) rgb
#else
    #define GONBEST_LINEAR_TO_GAMMA(rgb) rgb
    #define GONBEST_GAMMA_TO_LINEAR(rgb) GBGammaToLinearSpace (rgb)
#endif


#endif //GONBEST_LINEAR_GAMMA_CG_INCLUDED