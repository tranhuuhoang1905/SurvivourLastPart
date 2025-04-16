/*
Author:gzg
Date:2019-10-10
Desc:这个Shader只是一个模板,用于创建把Shadertoy上面的代码,扒下来在Unity上进行调试的Shader代码.主要是用于研究Shadertoy上渲染表现的实现方式.
    1.iChannel增加或者删除.
    2.替换 "类型(参数1,参数2...)" 的方式构造对象的方式,
    3.把const 替换为#define    
    4.其他的基本上都已经定义了.
*/
Shader "Gonbest/Shadertoy/Template" 
{ 
    Properties{
        iMouse ("Mouse Pos", Vector) = (100, 100, 0, 0)
        iChannel0("iChannel0", 2D) = "white" {}          
        iChannel1("iChannel1",2D)  = "white"{}
        iChannel2("iChannel2",2D)  = "white"{}
        iChannel3("iChannel3",2D)  = "white"{}
        iChannelResolution0 ("iChannelResolution0", Vector) = (100, 100, 0, 0)
    }
 
    CGINCLUDE    
    #include "UnityCG.cginc"   
    #pragma target 3.0      
 
    #define vec2 float2
    #define vec3 float3
    #define vec4 float4
	#define tvec2(x) (float2)x	
    #define tvec3(x) (float3)x	
    #define tvec4(x) (float4)x	
    #define ivec2 int2
    #define ivec3 int3
    #define ivec4 int4
    #define mat2 float2x2
    #define mat3 float3x3
    #define mat4 float4x4
    #define iTime _Time.y
    #define mod fmod
    #define mix lerp
    #define fract frac
    #define texture tex2D
    #define textureLod tex2Dlod
    #define iResolution _ScreenParams
    #define gl_FragCoord ((_iParam.scrPos.xy/_iParam.scrPos.w) * _ScreenParams.xy)
    #define lessThan(a,b) a < b
 
    #define PI2 6.28318530718
    #define pi 3.14159265358979
    #define halfpi (pi * 0.5)
    #define oneoverpi (1.0 / pi)
 
    fixed4 iMouse;
    sampler2D iChannel0;
    sampler2D iChannel1;
    sampler2D iChannel2;
    sampler2D iChannel3;
    fixed4 iChannelResolution0;
 
    struct v2f {    
        float4 pos : SV_POSITION;    
        float4 scrPos : TEXCOORD0;  
        float2 uv:TEXCOORD1; 
    };              
 
    v2f vert(appdata_base v) {  
        v2f o;
        o.pos = UnityObjectToClipPos (v.vertex);
        o.scrPos = ComputeScreenPos(o.pos);
        o.uv = v.texcoord.xy;
        return o;
    }  
 
    void mainImage( out vec4 fragColor, in vec2 fragCoord );
    #define USE_SCREEN_POS
    fixed4 frag(v2f _iParam) : COLOR0 { 
        #ifdef USE_SCREEN_POS
        vec2 fragCoord = gl_FragCoord;
        #else
        vec2 fragCoord = iResolution.xy * _iParam.uv;
        #endif
        vec4 fColor = vec4(0,0,0,0);
        mainImage(fColor,fragCoord);
        return fColor;
    }

    /*==================主要是替换下面的代码Begin===================*/
    void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
	{
        fragColor = vec4(1, 1, 1, 1);
    }
    /*==========================END=============================*/
 
    ENDCG    
 
    SubShader {    
        Pass {    
            CGPROGRAM    
 
            #pragma vertex vert    
            #pragma fragment frag    
            #pragma fragmentoption ARB_precision_hint_fastest     
 
            ENDCG    
        }    
    }     
    FallBack Off    
}