/*=============================================================
Author:gzg
Date:2019-08-20
Desc:法线相关的计算,缩放处理,混合处理等等.
=============================================================*/

#ifndef GONBEST_NORMAL_CG_INCLUDED
#define GONBEST_NORMAL_CG_INCLUDED
#include "MathCG.cginc"

//解析法线,并进行放大缩小处理
half3 GBUnpackScaleNormalRGorAG(half4 packednormal, half bumpScale)
{
    #if defined(UNITY_NO_DXT5nm)
        half3 normal = packednormal.xyz * 2 - 1;
        #if (SHADER_TARGET >= 30)
            // SM2.0: instruction count limitation
            // SM2.0: normal scaler is not supported
            normal.xy *= bumpScale;
        #endif
        return normal;
    #else
        // This do the trick
        packednormal.x *= packednormal.w;

        half3 normal;
        normal.xy = (packednormal.xy * 2 - 1);
        #if (SHADER_TARGET >= 30)
            // SM2.0: instruction count limitation
            // SM2.0: normal scaler is not supported
            normal.xy *= bumpScale;
        #endif
        normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
        return normal;
    #endif
}

//解析法线,并进行放大缩小处理
half3 GBUnpackScaleNormal(half4 packednormal, half bumpScale)
{
    return GBUnpackScaleNormalRGorAG(packednormal, bumpScale);
}


//混合两个发现的算法
half3 GBBlendNormals(half3 n1, half3 n2)
{
    return GBNormalizeSafe(half3(n1.xy + n2.xy, n1.z*n2.z));
}

#if defined(_GONBEST_USE_NORMAL_TEX_ON)
    uniform sampler2D _BumpMap;		      
    uniform float _BumpScale = 1;
    
#else

#endif


#endif //GONBEST_NORMAL_CG_INCLUDED