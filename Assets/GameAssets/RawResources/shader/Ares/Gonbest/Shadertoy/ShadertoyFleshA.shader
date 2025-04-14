/*
Author:gzg
Date:2019-10-10
Desc:这个Shader只是一个模板,用于创建把Shadertoy上面的代码,扒下来在Unity上进行调试的Shader代码.主要是用于研究Shadertoy上渲染表现的实现方式.
    1.iChannel增加或者删除.
    2.替换 "类型(参数1,参数2...)" 的方式构造对象的方式,
    3.把const 替换为#define    
    4.其他的基本上都已经定义了.
*/
Shader "Gonbest/Shadertoy/ShadertoyFleshA" 
{ 
    Properties{
        iMouse ("Mouse Pos", Vector) = (100, 100, 0, 0)
        iChannel0("iChannel0", 2D) = "white" {}  
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
    #define mat2 float2x2
    #define mat3 float3x3
    #define mat4 float4x4
    #define iTime _Time.y
    #define mod fmod
    #define mix lerp
    #define fract frac
    #define texture tex2D
    #define iResolution _ScreenParams
    #define gl_FragCoord ((_iParam.scrPos.xy/_iParam.scrPos.w) * _ScreenParams.xy)
 
    #define PI2 6.28318530718
    #define pi 3.14159265358979
    #define halfpi (pi * 0.5)
    #define oneoverpi (1.0 / pi)
 
    fixed4 iMouse;
    sampler2D iChannel0;
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
    //Pre Integrated sss LUT
    //Based on GPU pro 2 Pre Integrated subsurface scattering by Penner

    #define samples 360.0f
    #define PI 3.14159265359f


    float Gaussian ( float v, float r )
    {
        return 1.0f/sqrt(2.0f*PI*v)*exp(-(r*r)/(2.0f*v));
    }

    vec3 Scatter ( float r )
    {
        return Gaussian ( 0.0064f * 1.414f , r ) * vec3( 0.233f , 0.455f , 0.649f ) +
            Gaussian ( 0.0484f * 1.414f , r ) * vec3( 0.100f , 0.336f , 0.344f ) +
            Gaussian ( 0.1870f * 1.414f , r ) * vec3( 0.118f , 0.198f , 0.000f ) +
            Gaussian ( 0.5670f * 1.414f , r ) * vec3( 0.113f , 0.007f , 0.007f ) +
            Gaussian ( 1.9900f * 1.414f , r ) * vec3( 0.358f , 0.004f , 0.000f ) +
            Gaussian ( 7.4100f * 1.414f , r ) * vec3( 0.078f , 0.000f , 0.000f ) ;
    }


    vec3 CalculateSS( float r, float angle ){
        vec2 L = vec2(1.0f,0.0f);
        float stepOffset = 2.0f*PI/samples;
        
        float angleOffset = 0.0f;
        
        vec3 totalLight = tvec3(0.0f);
        vec3 totalWeights = tvec3(0.0f);
        
        for( float i = 0.0f; i < samples; i++){
            
            float segment = 2.0f * r * sin(angleOffset*0.5f);
            
            float surfacePointAngle =  angle + angleOffset + 2.0f * PI;
            float NdotL = max(0.0f,cos(surfacePointAngle));
            
            vec3 weights = Scatter(segment);
            totalWeights += weights;
            totalLight += NdotL * weights;
            
            angleOffset += stepOffset;
        }
        
        return totalLight/totalWeights;
    }

    void mainImage( out vec4 fragColor, in vec2 fragCoord )
    {
        
        //if( texelFetch(iChannel0,vec2(0,0),0).a == iResolution.x)
        //    discard;
       // else{
            vec2 uv = fragCoord.xy / iResolution.xy;
            fragColor.rgb = CalculateSS(1.0f/(uv.y*2.0f),uv.x*PI);
            
            fragColor.a = fragCoord.x == 0.0f && fragCoord.y == 0.0f ? iResolution.x : 0.0f;
       // }
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