Shader "Gonbest/Experiment/EyeLens"
{
	Properties
	{
	   	_Color ("Main Color", Color) = (1, 1, 1, 1)	
        _ColorMultiplier("Color Multipler",Range(0,5)) = 1  			
        _EnvCube ("EnvCube", 2D) = "white" {}
        _Glossiness("Smoothness",Range(0,1)) = 0.2  //光滑度	
        _Gray("Gray",Range(0,1)) = 0
        _ShadowPower("ShadowPower",Range(0,10)) = 1
	}
	CGINCLUDE

        
        #include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
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
		uniform sampler2D _EnvCube;	
        uniform float _Glossiness	;
        uniform float _ShadowPower;
		
	

		struct v2f_mksky
		{
			float4 pos 		: POSITION;			
			float4 wpos 	: TEXCOORD0;
            float3 wnormal  : TEXCOORD1;
            float2 uv :TEXCOORD2;
		};					

		v2f_mksky vert_mksky (appdata_full v) 
		{
			v2f_mksky o = (v2f_mksky)0;
            o.uv = v.texcoord.xy;
			o.wnormal = UnityObjectToWorldNormal(v.normal);
			o.wpos = mul(unity_ObjectToWorld, v.vertex);		
			o.pos = UnityObjectToClipPos(v.vertex );
			return o;
		}

		float4 frag_mksky(v2f_mksky i) : COLOR 
		{
			float3 V = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
			float3 N =  GBNormalizeSafe(i.wnormal);;            
			float3 R = reflect( -V, N );
			float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
            float3 H = GBNormalizeSafe(L+V);
			float3 lightColor = _LightColor0.rgb;			
			//反射的cube
            float f = FresnelLerpFast(0, 1 , 1 - dot(N,V));
			float4 cloudColor = tex2D(_EnvCube,i.uv) * _ColorMultiplier *_Color;
           
            float lum = GBLuminance(cloudColor);
            cloudColor = lerp(cloudColor,lum,_Gray);

            float3 spec = GGXTerm(dot(N,H),1-_Glossiness)* lightColor;

			float3 finalColor = spec + cloudColor ;
            finalColor =pow(finalColor,_ShadowPower);
            float a = lerp(0.1,_Color.a,lum);

			return fixed4(finalColor,a);
        }
	ENDCG
	
	SubShader
	{ 	
		Pass
		{
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