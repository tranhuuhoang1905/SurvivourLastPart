Shader "Gonbest/Legacy/SkyHelper"
{
	Properties
	{
	   	_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex("Base (RGB)", 2D) = "white" {}		
        _FogFactor("_FogFactor",float) = 0.5
		_SkyColor ("Sky Color", Color) = (0.02553246,0.03709318,0.1827586,1)
        _GroundColor ("Ground Color", Color) = (0.06617647,0.5468207,1,1)
		[HDR]_SunColor("SunColor",Color) = (1,1,1,1)
        _SunRadiusB ("Sun Radius B", Range(0, 1)) = 0
        _SunRadiusA ("Sun Radius A", Range(0, 1)) = 0
        _SunIntensity ("Sun Intensity", Float ) = 2
        _HorizonColor ("HorizonColor", Color) = (0.6838235,0.9738336,1,1)
        _Horizon2Size ("Horizon2 Size", Range(0, 8)) = 1.755868
        _Horion1Size ("Horion1 Size", Range(0, 8)) = 8
        _SkyupColor ("Sky up", Color) = (0,0.1332658,0.2647059,1)
        _CloudsCube ("Clouds", Cube) = "black" {}
	}
	CGINCLUDE

        #include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"        
		#include "../Include/Indirect/Lightmap&SHLightCG.cginc"

		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;		        
        //雾的参数
		uniform float _FogFactor;	
		 uniform float4 _SkyColor;
		uniform float4 _GroundColor;
		uniform float4 _SunColor;
		uniform float _SunRadiusB;
		uniform float _SunRadiusA;
		uniform float _SunIntensity;
		uniform float4 _HorizonColor;
		uniform float _Horizon2Size;
		uniform float _Horion1Size;
		uniform float4 _SkyupColor;
		uniform samplerCUBE _CloudsCube;		
		
		struct v2f_sky
		{
			float4 pos 		: POSITION;
			half4 uv 		: TEXCOORD0;								
			GONBEST_FOG_COORDS(1)
		};
		
		//通用功能的vert
		v2f_sky vert_skybox(appdata_full v)
		{
			v2f_sky o = (v2f_sky)0;
			o.pos = UnityObjectToClipPos(v.vertex);			
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);			
            float3 wpos = mul(unity_ObjectToWorld,v.vertex).xyz;
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.pos, wpos);			
			return o;
		}

        //天空盒子的frag
        fixed4 frag_skybox( v2f_sky i ) : COLOR 
        {
            fixed4 mainTex = tex2D(_MainTex, i.uv.xy);
            GONBEST_APPLY_COLOR_MULTIPLIER(mainTex)            	
            //对应模型雾的颜色
            GONBEST_APPLY_FOG(i, mainTex);	
            mainTex.rgb = lerp(mainTex.rgb, unity_FogColor.rgb, _FogFactor);
			#if defined(_GONBEST_SPEC_ALPHA_ON)
				mainTex.a = 0;
			#endif			
			return mainTex;
        }

		struct v2f_mksky
		{
			float4 pos 		: POSITION;			
			float4 wpos 	: TEXCOORD0;
            float3 wnormal  : TEXCOORD1;								
			GONBEST_FOG_COORDS(1)
		};					

		v2f_mksky vert_mksky (appdata_full v) 
		{
			v2f_mksky o = (v2f_mksky)0;
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
			//Y轴
			float3 Y = float3(0,-1,0);
			//视线与Y轴的夹角
			float VdY = dot(V,Y);
			//光线与视线的夹角
			float LdV = max(0,dot(-L,V));				

			float SunAreaA = 1 - _SunRadiusA * _SunRadiusA * 0.09;
			float SunAreaB = 1 - _SunRadiusB * _SunRadiusB * 0.05;		

			//天空和地面颜色
			float3 color0 = lerp(_SkyColor.rgb,_GroundColor.rgb,pow((1.0 - max(0,VdY)),_Horion1Size));
			//天空和地面连接色
			float3 color1 = lerp(color0,_HorizonColor.rgb,pow((1.0 - abs(VdY)),_Horizon2Size));
			//天空顶颜色
			float3 color3 = lerp(color1,_SkyupColor.rgb,saturate(2.5*VdY - 1.5668));
			//太阳的范围
			float3 sunColor = _SunColor * pow(saturate(1 - (LdV - SunAreaA) / (SunAreaB - SunAreaA)),5.0) * _SunIntensity;			
			//云彩
			float4 cloudColor = texCUBE(_CloudsCube,R);
			float3 emissive = lerp((color3 + sunColor),cloudColor.rgb,cloudColor.a);
			float3 finalColor = emissive;
			return fixed4(finalColor,0);
        }
	ENDCG
	
	SubShader
	{ 		
		Pass
		{	//为场景中的美术制作的天空盒子做处理
			Name "SKYBOX"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_skybox
			#pragma fragment frag_skybox
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF			
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			ENDCG
		}

		Pass
		{	//为场景中的美术制作的天空盒子做处理
			Name "SKYBOX&ALPHA"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			ZWrite off
			CGPROGRAM
			#pragma vertex vert_skybox
			#pragma fragment frag_skybox
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF			
			ENDCG
		}

		Pass
		{	//为场景中的美术制作的天空盒子做处理 -- 不带高度物
			Name "SKYBOX&NOHEIGHTFOG"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_skybox
			#pragma fragment frag_skybox
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON		
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON		
			ENDCG
		}

		Pass
		{	//为场景中的美术制作的天空盒子做处理 -- 不带高度物
			Name "SKYBOX&ALPHA&NOHEIGHTFOG"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			ZWrite off
			CGPROGRAM
			#pragma vertex vert_skybox
			#pragma fragment frag_skybox
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			ENDCG
		}

		Pass
		{	//为场景中的美术制作的天空盒子做处理
			Name "SKYBOX&CUBE"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_mksky
			#pragma fragment frag_mksky
			#pragma fragmentoption ARB_precision_hint_fastest		
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
		
	}
}