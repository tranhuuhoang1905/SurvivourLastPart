/*
Author:gzg
Date:2019-10-10
Desc:玉色,SSS的处理
*/
Shader "Gonbest/Shadertoy/ShadertoyGOO" 
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
   // MIT License: https://opensource.org/licenses/MIT

mat3 rotate( in vec3 v, in float angle){
	float c = cos(angle);
	float s = sin(angle);
	return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
		);
}

vec3 hash(vec3 p){
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

// Gradient noise from iq
// return value noise (in x) and its derivatives (in yzw)
vec4 noised(vec3 x){
    vec3 p = floor(x);
    vec3 w = fract(x);
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);
    
    vec3 ga = hash( p+vec3(0.0,0.0,0.0) );
    vec3 gb = hash( p+vec3(1.0,0.0,0.0) );
    vec3 gc = hash( p+vec3(0.0,1.0,0.0) );
    vec3 gd = hash( p+vec3(1.0,1.0,0.0) );
    vec3 ge = hash( p+vec3(0.0,0.0,1.0) );
	vec3 gf = hash( p+vec3(1.0,0.0,1.0) );
    vec3 gg = hash( p+vec3(0.0,1.0,1.0) );
    vec3 gh = hash( p+vec3(1.0,1.0,1.0) );
    
    float va = dot( ga, w-vec3(0.0,0.0,0.0) );
    float vb = dot( gb, w-vec3(1.0,0.0,0.0) );
    float vc = dot( gc, w-vec3(0.0,1.0,0.0) );
    float vd = dot( gd, w-vec3(1.0,1.0,0.0) );
    float ve = dot( ge, w-vec3(0.0,0.0,1.0) );
    float vf = dot( gf, w-vec3(1.0,0.0,1.0) );
    float vg = dot( gg, w-vec3(0.0,1.0,1.0) );
    float vh = dot( gh, w-vec3(1.0,1.0,1.0) );
	
    return vec4( va + u.x*(vb-va) + u.y*(vc-va) + u.z*(ve-va) + u.x*u.y*(va-vb-vc+vd) + u.y*u.z*(va-vc-ve+vg) + u.z*u.x*(va-vb-ve+vf) + (-va+vb+vc-vd+ve-vf-vg+vh)*u.x*u.y*u.z,    // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.z*(ge-ga) + u.x*u.y*(ga-gb-gc+gd) + u.y*u.z*(ga-gc-ge+gg) + u.z*u.x*(ga-gb-ge+gf) + (-ga+gb+gc-gd+ge-gf-gg+gh)*u.x*u.y*u.z +   // derivatives
                 du * (vec3(vb,vc,ve) - va + u.yzx*vec3(va-vb-vc+vd,va-vc-ve+vg,va-vb-ve+vf) + u.zxy*vec3(va-vb-ve+vf,va-vb-vc+vd,va-vc-ve+vg) + u.yzx*u.zxy*(-va+vb+vc-vd+ve-vf-vg+vh) ));
}

float map(vec3 p){
    // ugly hacky slow distance field with bad gradients
    float d = p.y;
    float c = max(0.0, pow(distance(p.xz, vec2(0,16)), 1.0));
    float cc = pow(smoothstep(20.0, 5.0, c), 2.0);
    //p.xz *= cc;
    vec4 n = noised(vec3(p.xz*0.07, iTime*0.5));
    float nn = n.x * (length((n.yzw)));
    n = noised(vec3(p.xz*0.173, iTime*0.639));
    nn += 0.25*n.x * (length((n.yzw)));
    nn = smoothstep(-0.5, 0.5, nn);
    d = d-6.0*nn*(cc);
    return d;
}

float err(float dist){
    dist = dist/100.0;
    return min(0.01, dist*dist);
}

vec3 dr(vec3 origin, vec3 direction, vec3 position){
    const int iterations = 3;
    for(int i = 0; i < iterations; i++){
        position = position + direction * (map(position) - err(distance(origin, position)));
    }
    return position;
}

vec3 intersect(vec3 ro, vec3 rd){
	vec3 p = ro+rd;
	float t = 0.;
	for(int i = 0; i < 150; i++){
        float d = 0.5*map(p);
        t += d;
        p += rd*d;
		if(d < 0.01 || t > 60.0) break;
	}
    
    // discontinuity reduction as described (somewhat) in
    // their 2014 sphere tracing paper
    p = dr(ro, rd, p);
    return p;
}

vec3 normal(vec3 p){
	float e=0.01;
	return GBNormalizeSafe(vec3(map(p+vec3(e,0,0))-map(p-vec3(e,0,0)),
	                      map(p+vec3(0,e,0))-map(p-vec3(0,e,0)),
	                      map(p+vec3(0,0,e))-map(p-vec3(0,0,e))));
}

float G1V(float dnv, float k){
    return 1.0/(dnv*(1.0-k)+k);
}

float ggx(vec3 n, vec3 v, vec3 l, float rough, float f0){
    float alpha = rough*rough;
    vec3 h = GBNormalizeSafe(v+l);
    float dnl = clamp(dot(n,l), 0.0, 1.0);
    float dnv = clamp(dot(n,v), 0.0, 1.0);
    float dnh = clamp(dot(n,h), 0.0, 1.0);
    float dlh = clamp(dot(l,h), 0.0, 1.0);
    float f, d, vis;
    float asqr = alpha*alpha;
    
    float den = dnh*dnh*(asqr-1.0)+1.0;
    d = asqr/(pi * den * den);
    dlh = pow(1.0-dlh, 5.0);
    f = f0 + (1.0-f0)*dlh;
    float k = alpha/1.0;
    vis = G1V(dnl, k)*G1V(dnv, k);
    float spec = dnl * d * f * vis;
    return spec;
}

float subsurface(vec3 p, vec3 v, vec3 n){
    //vec3 d = GBNormalizeSafe(mix(v, -n, 0.5));
    // suggested by Shane
    vec3 d = refract(v, n, 1.0/1.5);
    vec3 o = p;
    float a = 0.0;
    
    #define  max_scatter  2.5
    for(float i = 0.1; i < max_scatter; i += 0.2)
    {
        o += i*d;
        float t = map(o);
        a += t;
    }
    float thickness = max(0.0, -a);
    #define  scatter_strength  16.0
	return scatter_strength*pow(max_scatter*0.5, 3.0)/thickness;
}

vec3 shade(vec3 p, vec3 v){
    vec3 lp = vec3(50,20,10);
    vec3 ld = GBNormalizeSafe(p+lp);
    
    vec3 n = normal(p);
    float fresnel = pow( max(0.0, 1.0+dot(n, v)), 5.0 );
    
    vec3 final = tvec3(0);
    vec3 ambient = vec3(0.1, 0.06, 0.035);
    vec3 albedo = vec3(0.75, 0.9, 0.35);
    vec3 sky = vec3(0.5,0.65,0.8)*2.0;
    
    float lamb = max(0.0, dot(n, ld));
    float spec = ggx(n, v, ld, 3.0, fresnel);
    float ss = max(0.0, subsurface(p, v, n));
    
    // artistic license
    lamb = mix(lamb, 3.5*smoothstep(0.0, 2.0, pow(ss, 0.6)), 0.7);
    final = ambient + albedo*lamb+ 25.0*spec + fresnel*sky ;
    return vec3(final*0.5 * ss);
}

// linear white point
#define  W 1.2
#define  T2 7.5

float filmic_reinhard_curve (float x) {
    float q = (T2*T2 + 1.0)*x*x;    
	return q / (q + x + T2*T2);
}

vec3 filmic_reinhard(vec3 x) {
    float w = filmic_reinhard_curve(W);
    return vec3(
        filmic_reinhard_curve(x.r),
        filmic_reinhard_curve(x.g),
        filmic_reinhard_curve(x.b)) / w;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = fragCoord / iResolution.xy;
    vec3 a = tvec3(0);
    
    // leftover stuff from something else, too lazy to remove
    // don't ask
    #define  campos  5.1
    float lerp1 = 0.5+0.5*cos(campos*0.4-pi);
    lerp1 = smoothstep(0.13, 1.0, lerp1);
    vec3 c = mix(vec3(-0,217,0), vec3(0,4.4,-190), pow(lerp1,1.0));
    mat3 rot = rotate(vec3(1,0,0), pi/2.0);
    mat3 ro2 = rotate(vec3(1,0,0), -0.008*pi/2.0);
    
    vec2 u2 = -1.0+2.0*uv;
    u2.x *= iResolution.x/iResolution.y;

    vec3 d = mix(GBNormalizeSafe(mul(rot,vec3(u2, 20))), mul(ro2,GBNormalizeSafe(vec3(u2, 20))), pow(lerp1,1.11));
    d = GBNormalizeSafe(d);

    vec3 ii = intersect(c+145.0*d, d);
    vec3 ss = shade(ii, d);
    a += ss;
    
    vec3 color = a*(0.99+0.02*hash(vec3(uv,0.001*iTime)));
#define brightness 0.5
    color = filmic_reinhard(brightness*color);
    
    color = smoothstep(0, 1.0,color);
    
    color = pow(color, tvec3(1.0/2.2));
    fragColor = vec4(color, 1.0);
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