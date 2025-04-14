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
    #include "../Include/Base/MathCG.cginc"
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
    #define PI 3.14159265358979
    #define pi 3.14159265358979
    #define EPSILON	1e-3
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
        /*
        * "Seascape" by Alexander Alekseev aka TDM - 2014
        * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
        * Contact: tdmaav@gmail.com
        */

        #define NUM_STEPS  8
        #define EPSILON_NRM (0.1 / iResolution.x)
        #define AA

        // sea
        #define ITER_GEOMETRY   3
        #define  ITER_FRAGMENT   5
        #define  SEA_HEIGHT 0.6
        #define  SEA_CHOPPY   4.0
        #define  SEA_SPEED  0.8
        #define  SEA_FREQ  0.16
        #define  SEA_BASE   vec3(0.0,0.09,0.18)
        #define  SEA_WATER_COLOR   vec3(0.8,0.9,0.6)*0.6
        #define SEA_TIME  (1.0 + iTime * SEA_SPEED)
        #define  octave_m   float2x2(1.6,1.2,-1.2,1.6)

        // math
        float3x3 fromEuler(vec3 ang) {
            vec2 a1 = vec2(sin(ang.x),cos(ang.x));
            vec2 a2 = vec2(sin(ang.y),cos(ang.y));
            vec2 a3 = vec2(sin(ang.z),cos(ang.z));
            float3x3 m;
            m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
            m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
            m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
            return m;
        }
        float hash( vec2 p ) {
            float h = dot(p,vec2(127.1,311.7));	
            return fract(sin(h)*43758.5453123);
        }
        float noise( in vec2 p ) {
            vec2 i = floor( p );
            vec2 f = fract( p );	
            vec2 u = f*f*(3.0-2.0*f);
            return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                            hash( i + vec2(1.0,0.0) ), u.x),
                        mix( hash( i + vec2(0.0,1.0) ), 
                            hash( i + vec2(1.0,1.0) ), u.x), u.y);
        }

        // lighting
        float diffuse(vec3 n,vec3 l,float p) {
            return pow(dot(n,l) * 0.4 + 0.6,p);
        }
        float specular(vec3 n,vec3 l,vec3 e,float s) {    
            float nrm = (s + 8.0) / (PI * 8.0);
            return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
        }

        // sky
        vec3 getSkyColor(vec3 e) {
            e.y = (max(e.y,0.0)*0.8+0.2)*0.8;
            return vec3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4) * 1.1;
        }

        // sea
        float sea_octave(vec2 uv, float choppy) {
            uv += noise(uv);        
            vec2 wv = 1.0-abs(sin(uv));
            vec2 swv = abs(cos(uv));    
            wv = mix(wv,swv,wv);
            return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
        }

        float map(vec3 p) {
            float freq = SEA_FREQ;
            float amp = SEA_HEIGHT;
            float choppy = SEA_CHOPPY;
            vec2 uv = p.xz; 
            uv.x *= 0.75;
            
            float d, h = 0.0;    
            for(int i = 0; i < ITER_GEOMETRY; i++) {        
                d = sea_octave((uv+SEA_TIME)*freq,choppy);
                d += sea_octave((uv-SEA_TIME)*freq,choppy);
                h += d * amp;        
                //uv *= octave_m; 
                uv = mul(octave_m,uv);
                freq *= 1.9; 
                amp *= 0.22;
                choppy = mix(choppy,1.0,0.2);
            }
            return p.y - h;
        }

        float map_detailed(vec3 p) {
            float freq = SEA_FREQ;
            float amp = SEA_HEIGHT;
            float choppy = SEA_CHOPPY;
            vec2 uv = p.xz; 
            uv.x *= 0.75;
            
            float d, h = 0.0;    
            for(int i = 0; i < ITER_FRAGMENT; i++) {        
                d = sea_octave((uv+SEA_TIME)*freq,choppy);
                d += sea_octave((uv-SEA_TIME)*freq,choppy);
                h += d * amp;        
                //uv *= octave_m; 
                uv = mul(octave_m,uv);
                freq *= 1.9; 
                amp *= 0.22;
                choppy = mix(choppy,1.0,0.2);
            }
            return p.y - h;
        }

        vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) {  
            float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
            fresnel = pow(fresnel,3.0) * 0.5;
                
            vec3 reflected = getSkyColor(reflect(eye,n));    
            vec3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12; 
            
            vec3 color = mix(refracted,reflected,fresnel);
            
            float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
            color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
            
            color += specular(n,l,eye,60.0).xxx;
            
            return color;
        }

        // tracing
        vec3 getNormal(vec3 p, float eps) {
            vec3 n;
            n.y = map_detailed(p);    
            n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - n.y;
            n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - n.y;
            n.y = eps;
            return GBNormalizeSafe(n);
        }

        float heightMapTracing(vec3 ori, vec3 dir, out vec3 p) {  
            float tm = 0.0;
            float tx = 1000.0;    
            float hx = map(ori + dir * tx);
            if(hx > 0.0) return tx;   
            float hm = map(ori + dir * tm);    
            float tmid = 0.0;
            for(int i = 0; i < NUM_STEPS; i++) {
                tmid = mix(tm,tx, hm/(hm-hx));                   
                p = ori + dir * tmid;                   
                float hmid = map(p);
                if(hmid < 0.0) {
                    tx = tmid;
                    hx = hmid;
                } else {
                    tm = tmid;
                    hm = hmid;
                }
            }
            return tmid;
        }

        vec3 getPixel(in vec2 coord, float time) {    
            vec2 uv = coord / iResolution.xy;
            uv = uv * 2.0 - 1.0;
            uv.x *= iResolution.x / iResolution.y;    
                
            // ray
            vec3 ang = vec3(sin(time*3.0)*0.1,sin(time)*0.2+0.3,time);    
            vec3 ori = vec3(0.0,3.5,time*5.0);
            vec3 dir = GBNormalizeSafe(vec3(uv.xy,-2.0));
            dir.z += length(uv) * 0.14;
            dir = GBNormalizeSafe(dir) ;
            //dir = mul(fromEuler(ang),dir);

            
            // tracing
            vec3 p;
            heightMapTracing(ori,dir,p);
            vec3 dist = p - ori;
            vec3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
            vec3 light = GBNormalizeSafe(vec3(0.0,1.0,0.8)); 
                    
            // color
            return mix(
                getSkyColor(dir),
                getSeaColor(p,n,light,dir,dist),
                pow(smoothstep(0.0,-0.02,dir.y),0.2));
        }

        // main
        void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
            float time = iTime * 0.3 + iMouse.x*0.01;
            
        #ifdef AA
            vec3 color = (vec3)(0.0);
            for(int i = -1; i <= 1; i++) {
                for(int j = -1; j <= 1; j++) {
                    vec2 uv = fragCoord+vec2(i,j)/3.0;
                    color += getPixel(uv, time);
                }
            }
            color /= 9.0;
        #else
            vec3 color = getPixel(fragCoord, time);
        #endif
            
            // post
            fragColor = vec4(pow(color,0.65), 1.0);
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