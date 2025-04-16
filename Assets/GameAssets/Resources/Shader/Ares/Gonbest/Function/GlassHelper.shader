/*===============================================================
Author:gzg
Date:2019-10-19
Desc:玻璃效果的处理
=================================================================*/
Shader "Gonbest/Function/GlassHelper"
{
	Properties
	{
	   	_Color ("Main Color", Color) = (1, 1, 1, 1)	
        _ColorMultiplier("Color Multipler",Range(0,5)) = 1  			
        _MainTex ("MainTex", 2D) = "black" {}
        _UVMaskTex ("UVMaskTex", 2D) = "white" {}
        _Glossiness("Smoothness",Range(0,1)) = 0.2  //光滑度	
        _Gray("Gray",Range(0,1)) = 0
        _ShadowPower("ShadowPower",Range(0,1)) = 1
	}
	CGINCLUDE

        
        #include "../Include/Base/CommonCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"
		#include "../Include/Indirect/Lightmap&SHLightCG.cginc"
        #include "../Include/Specular/GGXCG.cginc"
        #include "../Include/Base/FresnelCG.cginc"
        #include "../Include/Base/EnergyCG.cginc"
			            
        uniform float _Gray;
        uniform float4 _Color;
        uniform float _ColorMultiplier;
		uniform sampler2D _MainTex;	
        uniform float4 _MainTex_TexelSize;
        uniform float _Glossiness;
        uniform float _ShadowPower;
        uniform sampler2D _UVMaskTex;
		
	

		struct v2f_mksky
		{
			float4 pos 		: POSITION;			
			float4 wpos 	: TEXCOORD0;
            float3 wnormal  : TEXCOORD1;
            float2 uv 		: TEXCOORD2;
			float3 wl       : TEXCOORD3;
		};					

		v2f_mksky vert_mksky (appdata_full v) 
		{
			v2f_mksky o = (v2f_mksky)0;
            o.uv = v.texcoord.xy;
            o.uv.x = 1 - o.uv.x;
			o.wnormal = UnityObjectToWorldNormal(v.normal);
			o.wpos = mul(unity_ObjectToWorld, v.vertex);		
			o.pos = UnityObjectToClipPos(v.vertex );
            #if defined(UNITY_UV_STARTS_AT_TOP)	
            if(_MainTex_TexelSize.y < 0)
            {
                o.uv.y = 1 - o.uv.y;
            }			
            #endif
			o.wl = _WorldSpaceLightPos0.xyz;
			return o;
		}

		float4 frag_mksky(v2f_mksky i) : COLOR 
		{
			float3 V = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
			float3 N =  GBNormalizeSafe(i.wnormal);         
			float3 R = reflect( -V, N );
			float3 L = GBNormalizeSafe(i.wl);
            float3 H = GBNormalizeSafe(L+V);
			float3 lightColor = _LightColor0.rgb;		
            float2 uvmask = tex2D(_UVMaskTex,i.uv).rg;
            float2 uv =i.uv;// uvmask.r > 0.9?  ( uvmask.r* 3) * i.uv - 1 : i.uv;
			//IBL环境光处理            
            float f = GBFresnelLerpFast(0, 1 , 1 - dot(N,V));
			float4 refCol = tex2D(_MainTex,uv) * _ColorMultiplier *_Color *f;
            //高光处理
            float3 spec = GGXTerm(dot(N,H),1-_Glossiness)*_ShadowPower;//* lightColor;

			float3 finalColor = refCol; 
             //去色处理
            float lum = GBLuminance(finalColor);
            finalColor = lerp(finalColor,lum,_Gray);
            //finalColor = pow(finalColor,_ShadowPower);
            float a = lerp(0.1,_Color.a,lum)* uvmask.g;

			return fixed4(finalColor,0);
        }
	ENDCG
	
	SubShader
	{ 	
		Pass
		{
            Name "COMMON"
			Tags { "LightMode" = "ForwardBase" }
            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_mksky
			#pragma fragment frag_mksky
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG
		}
		
	}
}