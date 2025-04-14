	
        #include "../Include/Base/MathCG.cginc"
		#include "../Include/Base/RampCG.cginc"
        #include "../Include/Indirect/RimLightCG.cginc"
        #include "../Include/Indirect/Lightmap&SHLightCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"        
        #include "../Include/Utility/FurUtilsCG.cginc"
        #include "../Include/Utility/PixelUtilsCG.cginc"

		struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;								
            float3 wpos:TEXCOORD1;
            float4 color:TEXCOORD2;
            float3 normal:TEXCOORD3;
            float3 diff:TEXCOORD4;
            float4 screenPos:TEXCOORD5;
            GONBEST_SH_COORDS(6)
            GONBEST_SHADOW_COORDS(7)
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _MaskTex;
        //uniform sampler2D _RampTex;
        uniform float4 _Color ;
        uniform float _ColorMultiplier;
        uniform float _ShadowRange;
        uniform float _ShadowPower;
        uniform float _ShadowSmooth;
        uniform float _SpecularRange;
        uniform float _SpecularPower;
        uniform float _RimRampSmooth = 0;
        uniform float _RimPower;
        uniform float4 _RimColor;   
        uniform float4 _EmissionColor;    
        uniform float _ShadowContrast;
                         
        uniform float _ISUI;
        
        v2f vert (appdata_full v)
        {
            v2f o = (v2f)0;
            float4 vpos = v.vertex;
            GONBEST_FUR_VERTEX_EXPAND(vpos,GBNormalizeSafe(v.normal),FURSTEP * v.color.r);
            GONBEST_FUR_VERTEX_FORCE(vpos,FURSTEP);
            float4 wpos = mul(unity_ObjectToWorld,vpos);
            o.wpos = wpos.xyz/wpos.w;
            o.pos = mul(UNITY_MATRIX_VP,wpos);
            o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
            o.color = v.color;
            o.normal = GBNormalizeSafe(mul(v.normal.xyz,(float3x3)unity_WorldToObject));
            o.diff = saturate(dot(o.normal,_WorldSpaceLightPos0.xyz)*0.5+0.5);                 
            GONBEST_TRANSFER_SH(o,o.normal,wpos);
            //阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);					
            return o;
        }        

        fixed4 frag (v2f i) : SV_Target
        {
            float3 P = i.wpos.xyz;
            float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
            float3 V = GetWorldViewDirWithUI(P, _ISUI);		
            float3 H = GBNormalizeSafe(L+V);
            float3 N = GBNormalizeSafe(i.normal);
            float NoV =  saturate(dot(N,V));
            
          
            float4 baseColor = tex2D(_MainTex,i.uv) * _Color * _ColorMultiplier;
            float4 mask = tex2D(_MaskTex,i.uv);
           
            //阴影1
            float3 sha = saturate(baseColor.rgb > 0.5 ? (1 - 2 * (1-baseColor.rgb) * (1 -  mask.g)) : 2 * baseColor.rgb *  mask.g);

            //阴影2
            float luminance = dot(gonbest_ColorSpaceLuminance.rgb, sha.rgb);
            luminance = lerp(luminance,1,_ShadowContrast);
            float3 sha1 = sha.rgb *saturate((sha.rgb/luminance) * _ShadowPower * 2);

            //diff
            float NoL = dot(N,L) * 0.5  + 0.5 + mask.g;
            NoL = NoL * _ShadowRange;
            NoL = RampTwoStep(NoL,0.2,_ShadowSmooth * 0.1);			    			    
            float3 diffuse = lerp(sha1, sha,NoL);

            //spec
            float specif = pow(NoV, mask.r);                
            float3 spec = step(_SpecularRange,specif);
            spec = step(0.1, spec * mask.b);
            spec *= _SpecularPower;
            spec *= NoL * sha;

            //rim
            float3 RimNoL = saturate(dot(N,GBNormalizeSafe(-L)));
            float rt = GBRimTerm(NoV, RimNoL,_RimPower);
            rt = RampTwoStep(rt,0.5,_RimRampSmooth*0.5);
            float3 rim =rt * _RimColor.rgb * _RimColor.a;

            //emissive
            float3 emissive = baseColor.rgb * mask.a * _EmissionColor.rgb;

            //final color
            float3 fColor = emissive + rim + diffuse + spec;

            float4 Out = float4(fColor,1);
           
            //皮毛处理
            GONBEST_FUR_APPLY_COLOR(Out,i.uv.xy,FURSTEP)
            return Out;
        }
    