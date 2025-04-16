/*
Author:gzg
Date:2019-10-10
Desc: 一个SSS的处理:
    https://www.shadertoy.com/view/llXBWn
    这里考虑对皮肤的处理

*/
Shader "Gonbest/Shadertoy/ShaderToySSS01" 
{ 
    Properties{
        iMouse ("Mouse Pos", Vector) = (100, 100, 0, 0)
        iChannel0("iChannel0", 2D) = "white" {}  
        iChannelResolution0 ("iChannelResolution0", Vector) = (100, 100, 0, 0)
    }
 
    CGINCLUDE    
    #include "UnityCG.cginc"   
    #include "../Include/Base/MathCG.cginc"
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
    //#define USE_SCREEN_POS
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
   // The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
// I tried to match Penner's paper on preintegrated SSS, Siggraph 2011. It's a visual approximation, this has nothing
// that has been done in any numerically meaningful way.
//
// See Nevi7's shader here for mroe info: https://www.shadertoy.com/view/4tXBWr
//


// Enable the one bellow to show the LUT
#define SHOW_LUT


// simpler approximation
//#define SIMPLE_APPROX


vec3 sss( float ndl, float ir )
{
    float pndl = clamp( ndl, 0.0, 1.0 );
    float nndl = clamp(-ndl, 0.0, 1.0 );

    
#ifndef SIMPLE_APPROX          
        return tvec3(pndl) + vec3(1.0,0.1,0.01) * 0.2 * (1.0-pndl) * (1.0-pndl) * pow(1.0-nndl, 3.0/(ir+0.001)) * clamp(ir-0.04,0.0,1.0);
#else
        return tvec3(pndl) + vec3(1.0,0.1,0.01) * 0.7 * pow(clamp(ir * 0.75 - nndl,0.0,1.0), 2.0);
#endif
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
#ifdef SHOW_LUT
	vec2 p = fragCoord / iResolution.xy;
    vec3 col = sss( -1.0+2.0*p.x, p.y );
#else    
	vec2 p = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;

	float an = 2.0 + 0.5*iTime + 6.2831*iMouse.x/iResolution.x;

	vec3 ww = vec3(cos(an),0.0,sin(an));
    vec3 uu = vec3(-ww.z,0.0,ww.x);
    vec3 vv = vec3(0.0,1.0,0.0);
    vec3 ro = -2.5*ww;
    
	vec3 rd = GBNormalizeSafe( p.x*uu + p.y*vv + 1.5*ww );

	vec3 col = tvec3(0.0);

	float b = dot( rd, ro );
	float c = dot( ro, ro ) - 1.0;
	float h = b*b - c;
	if( h>0.0 )
	{
		float t = -b - sqrt(h);
	    vec3 pos = ro + t*rd;
		vec3 nor = GBNormalizeSafe(pos); 
        const float r = 0.5;  // curvature
		col = vec3(1.0,0.9,0.8) * sss( dot(nor,tvec3(0.57703)), r );
	}
#endif
    
	col = pow( col, tvec3(0.4545) );
	
	
	fragColor = vec4( col, 1.0 );
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