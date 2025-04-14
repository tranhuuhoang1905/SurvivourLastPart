/*===============================================================
Author:gzg
Date:2019-08-20
Desc:这里存储一些基础的常量定义
===============================================================*/

#ifndef GONBEST_COMMON_CG_INCLUDED
#define GONBEST_COMMON_CG_INCLUDED

#include "UnityLightingCommon.cginc"
#include "UnityCG.cginc"

//PI的定义
#define GONBEST_PI            3.14159265359f
#define GONBEST_TWO_PI        6.28318530718f
#define GONBEST_FOUR_PI       12.56637061436f
#define GONBEST_INV_PI        0.31830988618f
#define GONBEST_INV_TWO_PI    0.15915494309f
#define GONBEST_INV_FOUR_PI   0.07957747155f
#define GONBEST_HALF_PI       1.57079632679f
#define GONBEST_INV_HALF_PI   0.636619772367f

//用于防止除零问题
#define GONBEST_EPSILON 1e-10

//定义颜色控件下的颜色值
#ifdef UNITY_COLORSPACE_GAMMA
	//灰度
	#define gonbest_ColorSpaceGrey fixed4(0.5, 0.5, 0.5, 0.5)
	//双倍颜色
	#define gonbest_ColorSpaceDouble fixed4(2.0, 2.0, 2.0, 2.0)
	//非金属高光的值
	#define gonbest_ColorSpaceDielectricSpec half4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301)
	//光强度的颜色值
	#define gonbest_ColorSpaceLuminance half4(0.22, 0.707, 0.071, 0.0) // Legacy: alpha is set to 0.0 to specify gamma mode
#else // Linear values
	//灰度
	#define gonbest_ColorSpaceGrey fixed4(0.214041144, 0.214041144, 0.214041144, 0.5)
	//双倍颜色
	#define gonbest_ColorSpaceDouble fixed4(4.59479380, 4.59479380, 4.59479380, 2.0)
	//非金属高光的值
	#define gonbest_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // 入射角标准介质反射率系数 standard dielectric reflectivity coef at incident angle (= 4%)
	//光强度的颜色值
	#define gonbest_ColorSpaceLuminance half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode
#endif

//==============================一些常用方法=======================================//

// Encoding/decoding [0..1) floats into 8 bit/channel RGBA. Note that 1.0 will not be encoded properly.
//把一个float值编码为一个颜色值
inline float4 GBEncodeFloatRGBA( float v )
{
	float4 kEncodeMul = float4(1.0, 255.0, 65025.0, 16581375.0);
	float kEncodeBit = 1.0/255.0;
	float4 enc = kEncodeMul * v;
	enc = frac (enc);
	enc -= enc.yzww * kEncodeBit;
	return enc;
}
//把一个颜色解析为一个float值
inline float GBDecodeFloatRGBA( float4 enc )
{
	float4 kDecodeDot = float4(1.0, 1/255.0, 1/65025.0, 1/16581375.0);
	return dot( enc, kDecodeDot );
}

//是否使用第二套UV
#if defined(_GONBEST_UV1_ON)
	#define GONBEST_UV1_COORDS(idx) float2 __uv1 : TEXCOORD##idx;
	#define GONBEST_TRANSFER_UV1(o,texcoord1) o.__uv1 = texcoord1.xy;
	#define GONBEST_UV1(i,uv)  i.__uv1
#else
	#define GONBEST_UV1_COORDS(idx)
	#define GONBEST_TRANSFER_UV1(o,texcoord1)
	#define GONBEST_UV1(i,uv) uv
#endif

#endif //GONBEST_COMMON_CG_INCLUDED