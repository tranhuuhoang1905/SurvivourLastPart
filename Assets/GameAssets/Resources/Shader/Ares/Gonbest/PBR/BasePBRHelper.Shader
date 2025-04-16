/*===============================================================
Author:gzg
Date:2020-01-02
Desc:基础PBR处理
===============================================================*/
Shader "Gonbest/PBR/BasePBRHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MainTex("Albedo", 2D) = "white" {}
		_BumpScale("Normal Map Scale",Range(0,2)) = 1  			//发现比率				
		_BumpMap("Normal Map",2D) = "black"{}		
		_Glossiness("Smoothness",Range(0,1)) = 0.2  //光滑度
		_Metallic("Metallic",Range(0,1)) = 0  //光滑度
		_OA("OA",Range(0,1)) = 0.5
		_MetallicTex("Metallic(R)&Glossiness(G)&AO(B)&Emissive(A)",2D) = "white"{}  	//金属度	
		_EnvDiffPower("Cube Diff Power",Range(0,4)) = 1
		_EnvSpecPower("Cube Spec Power",Range(0,4)) = 1
		_EnvCubeMipLevel("Cube MipLevel" , Range(0,100)) = 32
		_EnvCube("Cube Map", Cube) = "grey" {}
		_EmissiveColor ("Emissive Color", Color) = (0.7, 0.7, 0.7, 0.7)
		_SpecPower("SpecPower",Range(0,10)) = 1
        _ISUI("(> 0.5) is ui",float) = 0
	}

	CGINCLUDE		
		
		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Base/EnergyCG.cginc"
		#include "../Include/Base/NormalCG.cginc"		
		#include "../Include/Base/FresnelCG.cginc"		
		#include "../Include/Specular/SmithSchlickCG.cginc"	
		#include "../Include/Specular/BeckmannCG.cginc"	
		#include "../Include/Specular/GGXCG.cginc"
		#include "../Include/Indirect/IndirectSpecularCG.cginc"
		#include "../Include/Indirect/EnvBRDFCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"		
		#include "../Include/Utility/FlowUtilsCG.cginc"		
		#include "../Include/Utility/WidgetUtilsCG.cginc"
		#include "../Include/Utility/PixelUtilsCG.cginc"

		uniform sampler2D _MainTex;				
		uniform float4 _MainTex_ST;
		uniform sampler2D _MetallicTex;
		uniform sampler2D _BumpMap;		
		uniform float4 _EnvCube_HDR;
		UNITY_DECLARE_TEXCUBE(_EnvCube);
		uniform float _Glossiness;
		uniform float _Metallic;		
		uniform float _BumpScale;
		uniform float3 _EmissiveColor;				
		uniform float _SpecPower;
		uniform float _EnvDiffPower;
		uniform float _EnvSpecPower;
		uniform float _OA;
		uniform float _ISUI;
			
		struct v2f_base
		{
			float4 pos	: SV_POSITION;
			float4 uv	: TEXCOORD0;
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;		
			GONBEST_FOG_COORDS(4)	
		};

		v2f_base vert_base(appdata_full v)
		{
			v2f_base o =(v2f_base)0;			
			float4 ppos,wpos;
			float3 wt,wn,wb;    
			GetVertexParameters(v.vertex, v.tangent, v.normal, ppos, wpos, wn, wt, wb);
			o.pos = ppos;
			o.wt = float4(wt,wpos.x);        
			o.wb = float4(wb,wpos.y);
			o.wn = float4(wn,wpos.z);								
			//纹理坐标	
			o.uv.xy = TRANSFORM_TEX( v.texcoord, _MainTex );
			o.uv.zw = GONBEST_CALC_FLOW_UV(v, GONBEST_USE_FLOW_UV(v.texcoord,v.texcoord1));		
			//获取雾的采样点			
			GONBEST_TRANSFER_FOG(o, o.pos, wpos);	
			return o;
		}

		fixed4 frag_base(v2f_base i) :COLOR
		{
			float4 color = GONBEST_TEX_SAMPLE(_MainTex,i.uv.xy);

			//处理颜色值
			GONBEST_APPLY_COLOR_MULTIPLIER(color)

			//应用AlphaTest
			GONBEST_APPLY_ALPHATEST(color)
			
			

			//处理粗糙度和金属度
			float4 metaColor = tex2D(_MetallicTex,i.uv);
			float smoothness = _Glossiness * metaColor.g;
			float perceptualRoughness = max(0.08, 1 - smoothness);
			float rough = perceptualRoughness * perceptualRoughness;
			float meta = _Metallic * metaColor.r;
			fixed isui = step(0.5, _ISUI);

			//自发光
			float3 emissive = _EmissiveColor * color * metaColor.a;	
		
			float oa = _OA * metaColor.b;
			//处理高亮值
			float specPowner = _SpecPower * GONBEST_INV_PI;

			//根据能量守恒获取基础的散射光和高亮光颜色
			half oneMinusReflectivity;
			float3 diffColor,specularColor;
			GetDiffuseAndSpecular(color, meta, diffColor, specularColor, oneMinusReflectivity);

			//处理法线
			float4 NT = tex2D(_BumpMap,i.uv.xy);
			float3 N = GetWorldNormalFromBump(NT,_BumpScale,GBNormalizeSafe(i.wt.xyz),GBNormalizeSafe(i.wb.xyz),GBNormalizeSafe(i.wn.xyz));			
			float3 P = float3(i.wt.w, i.wb.w, i.wn.w);			
			
			//视线
			float3 V = GetWorldViewDirWithUI(P.xyz, isui);
			float3 R = reflect(-V,N);

			//主光
			float3 L = GetWorldUnityLightDir(P.xyz);
			float3 H = GBNormalizeSafe(L+V);	
			float NoL = saturate(dot(N,L));
			float NoV = saturate(dot(N,V));
			float NoH = saturate(dot(N,H));
			float VoH = saturate(dot(V,H));
			float VoL = dot(V,L);

			//漫反射
			float3 diff =_LightColor0.rgb * NoL ;			

			//高光			
        	float GGX = GBGGXSpecularTerm(NoH, NoL,NoV, rough);
			float3 F = GBFresnelTermFastWithSpecGreen(specularColor,VoH);			
			float3 spec = GGX * F * diff ;
		
			//间接光
			float3 indirect = IndirectSpecular_Custom(UNITY_PASS_TEXCUBE(_EnvCube), _EnvCube_HDR,R,rough,meta) ;
			indirect *= SurfaceReductionTerm(rough,perceptualRoughness);
			indirect *= GBFresnelLerp(specularColor,GrazingTerm(smoothness,oneMinusReflectivity),NoV);
			indirect *= lerp(_EnvDiffPower,_EnvSpecPower, meta);
			
			float4 Out = (float4)0;			
			Out.rgb = diff * diffColor;
			Out.rgb += spec *specPowner ;
			Out.rgb += indirect * oa;
			Out.rgb += emissive;			
			Out.a = color.a;					
			Out = saturate(Out);
		    
			//对应模型雾的颜色
			GONBEST_APPLY_FOG_CHECK_UI(i, Out.rgb, isui);
			#if defined(_GONBEST_SPEC_ALPHA_ON)
				color.a = max(0,spec *specPowner);
			#endif
			return Out;
		}
    ENDCG	
	
	SubShader
	{ 
		ZTest LEqual
	    Lighting Off
		ZWrite On				
		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
					
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON				
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	


		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND"			
			Tags { "LightMode" = "ForwardBase" }			
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC															
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	

        Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLOW"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON						
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&FLOW"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
					
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON				
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	


		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLOW"			
			Tags { "LightMode" = "ForwardBase" }			
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON											
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	
	    Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLUX"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON	
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON						
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&FLUX"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
					
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON	
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	


		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLUX"			
			Tags { "LightMode" = "ForwardBase" }			
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON	
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON										
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}

		/****************** DoubleFace ********************/
		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLOW&DOUBLEFACE"			
			Tags { "LightMode" = "ForwardBase" }			
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha			
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON											
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	
	}
}