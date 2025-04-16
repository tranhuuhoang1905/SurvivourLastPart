/*
Author:gzg
Date:2019-10-10
Desc:这个Shader只是一个模板,用于创建把Shadertoy上面的代码,扒下来在Unity上进行调试的Shader代码.主要是用于研究Shadertoy上渲染表现的实现方式.
    1.iChannel增加或者删除.
    2.替换 "类型(参数1,参数2...)" 的方式构造对象的方式,
    3.把const 替换为#define    
    4.其他的基本上都已经定义了.
*/
Shader "Gonbest/Shadertoy/ShadertoyFleshB" 
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
    //By Nestor Vina
    //#define iqMethodComparison

    const vec3 sunDir = GBNormalizeSafe(vec3(1.0,-1.0,1.0));

    // math
    #define  PI 3.14159265359
    #define  DEG_TO_RAD  PI / 180.0

    mat3 RotationXY( vec2 angle ) {
        vec2 c = cos( angle );
        vec2 s = sin( angle );
        
        return mat3(
            c.y      ,  0.0, -s.y,
            s.y * s.x,  c.x,  c.y * s.x, 
            s.y * c.x, -s.x,  c.y * c.x
        );
    }

    float Random( in vec3 value){
        return fract(sin(dot(value,vec3(1274.0546,1156.01549,1422.65229)))*15554.0);    
    }

    float Noise3D( in vec3 uv ){
        vec3 index = floor(uv);
        vec3 frac11 = fract(uv);
        
        float a = Random(index);
        float b = Random(index+vec3(1.0,0.0,0.0));
        float c = Random(index+vec3(0.0,1.0,0.0));
        float d = Random(index+vec3(1.0,1.0,0.0));
        
        float f = Random(index+vec3(0.0,0.0,1.0));
        float g = Random(index+vec3(1.0,0.0,1.0));
        float h = Random(index+vec3(0.0,1.0,1.0));
        float i = Random(index+vec3(1.0,1.0,1.0)); 
        
        frac11 = frac11*frac11*(3.0 - 2.0 * frac11);
        
        return mix(mix(mix(a,b,frac11.x),mix(c,d,frac11.x),frac11.y),
            mix(mix(f,g,frac11.x),mix(h,i,frac11.x),frac11.y),
            frac11.z);    
    }

    float FBMNoise3D6( in vec3 uv){
        float fbm = Noise3D(uv*0.1)*0.5;
        fbm += Noise3D(uv*0.2)*0.25;
        fbm += Noise3D(uv*0.4)*0.125;
        fbm += Noise3D(uv*0.8)*0.0625;
        fbm += Noise3D(uv*0.16)*0.03125;
        fbm += Noise3D(uv*0.32)*0.03125;    
        return fbm;
    }

    vec2 Map( vec3 p) {
        
        float noise = sqrt(sqrt(FBMNoise3D6(p*6.0f)));
        noise = mix(noise,FBMNoise3D6(p*15.0f),0.1f);
        
        float sdf = length(p) -10.0f;
        float defTime = iTime;
        float deformation = sin(p.x*0.7f+defTime)*sin(p.y*0.03f)*sin(p.z*0.1f)*3.0f;

        sdf += noise;
        sdf += deformation;
            
        return vec2(sdf, noise);    
    }

    vec2 Intersect( vec3 origin, vec3 dir, float start, float end ) {
        
        float depth = start;
        for ( int i = 0; i < 100; i++ ) {
            vec2 distResult = Map( origin + dir * depth );
            depth += distResult.x;
            if ( depth >= end) {
                return vec2(end,-1.0);
            }        
            if ( distResult.x < 0.02 ) {
                return vec2(depth,distResult.y);
            }
            
        }
        return vec2(end,-1.0);
    }

    vec3 RayDir( float fov, vec2 size, vec2 pos ) {
        vec2 xy = pos - size * 0.5;
        float cot_half_fov = tan( ( 90.0 - fov * 0.5 ) * DEG_TO_RAD );	
        float z = size.y * 0.5 * cot_half_fov;	
        return GBNormalizeSafe( vec3( -xy, -z ) );
    }

    vec3 Normal( vec3 pos ) {
        #define  normal_step  0.02
        vec3 dx = vec3( normal_step, 0.0, 0.0 );
        vec3 dy = vec3( 0.0, normal_step, 0.0 );
        vec3 dz = vec3( 0.0, 0.0, normal_step );
        return GBNormalizeSafe (
            vec3(
                Map( pos + dx ).x - Map( pos - dx ).x,
                Map( pos + dy ).x - Map( pos - dy ).x,
                Map( pos + dz ).x - Map( pos - dz ).x			
            )
        );
    }


    //iq's penner approximattion (see comments)
    vec3 sss( float ndl, float ir )
    {
        float pndl = clamp( ndl, 0.0, 1.0 );
        float nndl = clamp(-ndl, 0.0, 1.0 );
        
        return tvec3(pndl) + 
            vec3(1.0,0.2,0.05)*0.250*(1.0-pndl)*(1.0-pndl)*pow(1.0-nndl,3.0/(ir+0.001))*clamp(ir-0.04,0.0,1.0);
    }

    //My in-progress attempt
    vec3 nsss( float ndl, float ir ){
        float pndl = clamp( ndl, 0.0, 1.0 );
        float nndl = clamp(-ndl, 0.0, 1.0 )*0.4f;
        
        float inndle4 = 1.0f-nndl; inndle4 *= inndle4; inndle4 *= inndle4;
        
        return tvec3(pndl) + vec3(0.2f,0.02f,0.01f)*inndle4*ir*4.0f;
    }

    vec3 material( vec3 p, vec3 n, vec3 eye, float ao, vec2 screenCoords ) {    
        
        vec3 lightDir = GBNormalizeSafe(vec3(1.0f,-1.0f,-0.5f));
        
        float powao = ao*ao*ao;
        vec3 matColor = mix(vec3(0.713f,0.25f,0.2f),vec3(0.2,0.0f,0.0f), powao);
        
        vec3 dir = GBNormalizeSafe(p-eye);    
        float spec = pow(max(0.0f,dot(lightDir,reflect(dir,n))),40.0f)*(1.0f-ao);
        
        float ndotl = dot(-lightDir,n);
        float bndotl = dot(-lightDir,GBNormalizeSafe(p));    
        float smallCurvature = (1.0f-ao)*0.05f;
        
        #ifdef iqMethodComparison
            vec3 ss; 
            vec3 bss; 
            float mouseCurvatureControl = (iMouse.y / iResolution.y-0.5f)*2.0f;
            if(screenCoords.x < 0.5f){
                ss = sss(-bndotl,0.15f+smallCurvature + mouseCurvatureControl);
                bss = sss(-bndotl,0.15f+smallCurvature + mouseCurvatureControl);
            }
            else{
                ss = texture(iChannel0, vec2(ndotl*0.5f+0.5f,0.15f+smallCurvature+mouseCurvatureControl)).rgb;
                bss = texture(iChannel0, vec2(bndotl*0.5f+0.5f,0.15f+smallCurvature+mouseCurvatureControl)).rgb;
            }
        
        #else
            vec3 ss = texture(iChannel0, vec2(ndotl*0.5f+0.5f,0.15f+smallCurvature)).rgb;
            vec3 bss = texture(iChannel0, vec2(bndotl*0.5f+0.5f,0.15f+smallCurvature)).rgb;
        #endif
        
        return matColor * mix(bss,ss,1.0f-ao) + spec;
    }

    void mainImage( out vec4 fragColor, in vec2 fragCoord )
    {
        vec3 dir = RayDir( 45.0, iResolution.xy, fragCoord.xy );
        vec3 eye = vec3( 0.0, 0.0, 50.0 );

        mat3 rot = RotationXY( vec2(0,2.0f*PI*(iMouse.x/iResolution.x)));
        dir = mul(rot , dir);
        eye = mul(rot , eye);
        
        vec2 rayResult = Intersect( eye, dir, 0.0, 1000.0 );
        
        float depth = rayResult.x;
        
        if ( depth >= 1000.0 ) {        
            fragColor = vec4(0.0f,0.0f,0.0f,depth);
            return;
        }
        
        vec3 pos = eye + dir * depth;
        vec3 n = Normal( pos );
        vec3 fogColor = vec3(0.3f,0.3f,0.3f);
        
        fragColor = vec4(material( pos, n, eye, rayResult.y, fragCoord/iResolution.xy ), depth);
        
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