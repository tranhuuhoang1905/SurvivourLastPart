/*===============================================================
Author:gzg
Date:2020-01-02
Desc:针对颜色进行处理
===============================================================*/

#ifndef GONBEST_COLOR_CG_INCLUDED
#define GONBEST_COLOR_CG_INCLUDED
#include "CommonCG.cginc"

//设置亮度
//设置亮度很简单,就是把当前颜色乘与一个值就可以了.
inline fixed3 GBSetBrightness(fixed3 color,fixed power)
{
    return color * power;  
}

//设置饱和度
//饱和度是指色彩的纯度，越高色彩越纯，低则逐渐变灰，取0-100%的数值。
//饱和度是离灰度偏离越大，饱和度越大，我们首先可以计算一下同等亮度条件下饱和度最低的值，根据公式：gray = 0.2125 * r + 0.7154 * g + 0.0721 * b即可求出该值（公式应该是一个经验公式），然后我们使用该值和原始图像之间用一个系数进行差值，即可达到调整饱和度的目的。
inline fixed3 GBSetSaturation(fixed3 color,fixed power)
{
    fixed gray = dot(color,fixed3(0.2125,0.7154,0.0721));
    return lerp((fixed3)gray,color,power);
}

//设置对比度
//对比度表示颜色差异越大对比度越强，当颜色为纯灰色，也就是（0.5,0.5,0.5）时，对比度最小，我们通过在对比度最小的图像和原始图像通过系数差值，达到调整对比度的目的
inline fixed3 GBSetContrast(fixed3 color,fixed power)
{
    return lerp((fixed3)0.5,color,power);
}


//色相转换为RGB 
//色相(hue) 基本颜色,例如红色、黄色、绿色和蓝色
inline fixed3 GBHUEtoRGB(float H)
{
    float R = abs(H * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(H * 6.0 - 2.0);
    float B = 2.0 - abs(H * 6.0 - 4.0);
    return saturate(fixed3(R,G,B));
}
 
//HSL转换为RGB
//HSL即色相、饱和度、亮度（英语：Hue, Saturation, Lightness）。
//色相（H）是色彩的基本属性，就是平常所说的颜色名称，如红色、黄色等。
//饱和度（S）是指色彩的纯度，越高色彩越纯，低则逐渐变灰，取0-100%的数值。
//明度（V），亮度（L），取0-100%。
inline fixed3 GBHSLtoRGB(in fixed3 HSL)
{
    fixed3 RGB = GBHUEtoRGB(HSL.x);
    float C = (1.0 - abs(2.0 * HSL.z - 1.0)) * HSL.y;
    return (RGB - 0.5) * C + (fixed3)HSL.z;
}


inline fixed3 GBRGBtoHCV(fixed3 RGB)
{
    // Based on work by Sam Hocevar and Emil Persson
    fixed4 P = (RGB.g < RGB.b) ? fixed4(RGB.bg, -1.0, 2.0/3.0) : fixed4(RGB.gb, 0.0, -1.0/3.0);
    fixed4 Q = (RGB.r < P.x) ? fixed4(P.xyw, RGB.r) : fixed4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6.0 * C + GONBEST_EPSILON) + Q.z);
    return fixed3(H, C, Q.x);
}
 
 ///RGB转化为HSL 
inline fixed3 GBRGBtoHSL(fixed3 RGB)
{
    fixed3 HCV = GBRGBtoHCV(RGB);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1.0 - abs(L * 2.0 - 1.0) + GONBEST_EPSILON);
    return fixed3(HCV.x, S, L);
}

//颜色温度转换为RGB
float3 GBColorTemperatureToRGB(float temperatureInKelvins)
{
	float3 retColor;
	
    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;
    
    if (temperatureInKelvins <= 66.0)
    {
        retColor.r = 1.0;
        retColor.g = saturate(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098);
    }
    else
    {
    	float t = temperatureInKelvins - 60.0;
        retColor.r = saturate(1.29293618606274509804 * pow(t, -0.1332047592));
        retColor.g = saturate(1.12989086089529411765 * pow(t, -0.0755148492));
    }
    
    if (temperatureInKelvins >= 66.0)
        retColor.b = 1.0;
    else if(temperatureInKelvins <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = saturate(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914);
 
    return retColor;
}

//获取亮度
inline float GBGetLightness(float3 color)
{
    float fmin = min(min(color.r, color.g), color.b);
	float fmax = max(max(color.r, color.g), color.b);
	return (fmax + fmin) / 2.0;
}

//设置颜色的温度
inline float3 GBSetTemperature(float3 color,float power)
{
    float colorTempK = lerp(1000,40000,power);
    float3 colorTempRGB = GBColorTemperatureToRGB(colorTempK);
    float originalLuminance = GBGetLightness(color);
    float3 blended = lerp(color, color * colorTempRGB, power*2);
    float3 resultHSL = GBRGBtoHSL(blended);
    float3 luminancePreservedRGB = GBHSLtoRGB(float3(resultHSL.x, resultHSL.y, originalLuminance)); 
    return lerp(blended, luminancePreservedRGB, 0.75);
}



/*==========================宏定义================================*/

//亮度
#if defined(_GONBEST_ADJUST_BRIGHTNESS_ON)
    uniform float _BrightnessPower;
    #define GONBEST_ADJUST_BRIGHTNESS_APPLY(color) color = GBSetBrightness(color,_BrightnessPower);
#else
    #define GONBEST_ADJUST_BRIGHTNESS_APPLY(color)
#endif

//饱和度
#if defined(_GONBEST_ADJUST_SATURATION_ON)
    uniform float _SaturationPower;
    #define GONBEST_ADJUST_SATURATION_APPLY(color) color = GBSetSaturation(color,_SaturationPower);
#else
    #define GONBEST_ADJUST_SATURATION_APPLY(color)
#endif

//对比度
#if defined(_GONBEST_ADJUST_CONTRAST_ON)
    uniform float _ContrastPower;
    #define GONBEST_ADJUST_CONTRAST_APPLY(color) color = GBSetContrast(color,_ContrastPower);
#else
    #define GONBEST_ADJUST_CONTRAST_APPLY(color)
#endif

//温度
#if defined(_GONBEST_ADJUST_TEMPERATURE_ON)
    uniform float _TemperaturePower;
    #define GONBEST_ADJUST_TEMPERATURE_APPLY(color) color = GBSetTemperature(color,_TemperaturePower);
#else
    #define GONBEST_ADJUST_TEMPERATURE_APPLY(color)
#endif

#endif