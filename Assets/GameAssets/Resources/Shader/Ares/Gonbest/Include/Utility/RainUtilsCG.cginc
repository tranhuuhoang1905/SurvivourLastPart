/*
Author:gzg
Date:2019-08-20
Desc:下雨的效果宏的处理,地面覆盖的光纹效果
*/

#ifndef GONBEST_RAINUTILS_CG_INCLUDED
#define GONBEST_RAINUTILS_CG_INCLUDED
#include "../Base/Hash&NoiseCG.cginc"
#include "../Base/MathCG.cginc"

#ifdef _GONBEST_RAIN_BUMP_ON

    //噪音图
    uniform sampler2D _NoiseMap;
    //噪音法线图
    uniform sampler2D _NoiseBumpMap;      	
    //噪音重叠次数
    uniform float _NoiseTiling;	
    //噪音影响的强度	
    uniform float _NoisePower;
    //雨水的轻度
    uniform float _RainStength = 1;        
    //雨水的数独
    uniform float _RainSpeed = 1;  

    //根据噪音贴图来形成涟漪法线
    inline float4 _noiseNormal(float4 bumpColor,float2 uv)
    {
        //读取噪音文件
        float2 nuv = _NoiseTiling * uv.xy;
        float2 noise = tex2D(_NoiseMap,nuv).xy;

        noise = noise * _NoisePower + nuv;	

        float2 speed = _RainSpeed * _Time.xx;

        //读取噪音法线纹理
        float4 NN01 = tex2D(_NoiseBumpMap, noise + speed);

        float4 NN02 = tex2D(_NoiseBumpMap, noise - speed);
        
        float4 NN = (NN01 + NN02) * 0.5;

        return (NN - bumpColor) * _RainStength + bumpColor;			
    }
    #define GONBEST_RAIN_NORMAL(bumpColor,uv) bumpColor = _noiseNormal(bumpColor,uv);
#else
    //使用噪音算法来计算雨点涟漪
    #ifdef _GONBEST_RAIN_MATH_ON    
        //雨水的强度
        uniform float _RainStength = 1;        
        //雨水的速度
        uniform float _RainSpeed = 1;   
        //噪音重叠次数
        uniform float _NoiseTiling; 

        /*===========================通过噪音制作水滴涟漪的代码===================================*/
        //水波--倍频
        float _seaOctave(float2 uv)
        {
            uv += GBNoise1(uv);
            float2 wv = 1.0 - abs(sin(uv));
            float2 swv = abs(cos(uv));
            wv= lerp(wv, swv, wv);
            return 1.0- pow( wv.x*wv.y , 0.65 );
        }

        //根据计算形成涟漪法线
        float3 _noiseNormal(in float3 N,in float2 uv)
        {
            float4 jitterUV;
            //涟漪的重复数量Tiling
            jitterUV= (uv.xyxy * float4(1.5,5,5,1.5)) * _NoiseTiling;
            
            float4 seed= clamp((N.xzxz*10000), -1 , 1) * float4(20,20,6,6) *(_Time.y)*_RainSpeed;
            
            float R1= _seaOctave(jitterUV.yx * 10 - seed.x) + _seaOctave(float2(jitterUV.z * 3 - seed.z, jitterUV.w * 3));
            
            float R3= _seaOctave(jitterUV.xy * 4  - seed.w) + _seaOctave(jitterUV.zw * 8- seed.y);	
            R3 *= 0.5;	
            
            float R_D= (R1 * N.x + R3 * N.z) * 5 + (R1 + R3) * 0.1;
            R_D *= step(0.5,_RainStength) * _RainStength  * 1.3;
            
            return GBNormalizeSafe( lerp(N + float3(0,0,R_D), N, 1 - 0.2*saturate(N.y)) );
        }
        #define GONBEST_RAIN_NORMAL(wNormal,uv) wNormal = _noiseNormal(wNormal,uv);
    #else
        #define GONBEST_RAIN_NORMAL(bumpColor,uv)
    #endif
#endif

#ifdef _GONBEST_NOISE_LIGHT_LINE_ON
    //噪音图
    uniform sampler2D _NoiseMap;
    //噪音法线图
    uniform sampler2D _NoiseBumpMap;      	
    //噪音重叠次数
    uniform float _NoiseTiling;	
    //噪音影响的强度	
    uniform float _NoisePower;
    //雨水的轻度
    uniform float _RainStength = 1;        
    //雨水的数独
    uniform float _RainSpeed = 1;  

    inline float3 _noiseLightLine(float2 uv)
    {
        //读取噪音法线纹理
        float4 NN01 = tex2D(_NoiseBumpMap, uv + abs(frac(_Time.y * _RainSpeed) - 0.5) * 2);
        return tex2D(_NoiseMap,uv.xy * _NoiseTiling + NN01.xy * _RainStength) * _NoisePower;
    }

    #define GONBEST_NOISE_LIGHT_LINE_APPLY(color,uv)  color.rgb += _noiseLightLine(uv);
#else
    #define GONBEST_NOISE_LIGHT_LINE_APPLY(color,uv)    
#endif

#endif //GONBEST_RAINUTILS_CG_INCLUDED