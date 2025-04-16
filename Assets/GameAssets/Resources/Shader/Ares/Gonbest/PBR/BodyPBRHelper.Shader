/*===============================================================
Author:gzg
Date:2020-01-02
Desc:角色PBR处理
===============================================================*/
Shader "Gonbest/PBR/BodyPBRHelper"
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
		_MetallicTex("Metallic(R)&Glossiness(G)&Skin(B)",2D) = "white"{}  	//金属度	
		_EnvDiffPower("Cube Diff Power",Range(0,4)) = 1
		_EnvSpecPower("Cube Spec Power",Range(0,4)) = 1
		_EnvCubeMipLevel("Cube MipLevel" , Range(0,100)) = 32
		_EnvCube("Cube Map", Cube) = "grey" {}	
		_DiffuseColor ("Diffuse Color", Color) = (0.7, 0.7, 0.7, 0.7)				
		_SpecPower("SpecPower",Range(0,10)) = 1			
		_OA("OA",Range(0,1)) = 0.5
		_MainLightPos("Main Light Pos",Vector) = (0,0,0,1)
		_MainLightColor("Main Light Color",Color) = (1,1,1,1)
		_FillInLightPos("Fill In Light Pos",Vector) = (0,0,0,0)
		_FillInLightColor("Fill In Light Color",Color) = (1,1,1,1)			
		_MaskTex("Flow(R)&Flash(G)&LogicColor(B) MaskTex",2D) = "black"{}  	//Mask贴图
		_FlowTex ("Flow (RGB)", 2D) = "black" {}		
		_FlowNoiseTex ("Flow Distort Noise Tex (RG)", 2D) = "black" {}
		_FlowType ("Flow Type:(T<1,T<2,T<3,T>3)", Float) = 0
		_FlowStrength("FlowStrength",Range(0,2)) = 1
		_FlowSpeed ("Flow Speed", Float) = 1.0
		_FlowTileCount("Flow Tile Count",Float) = 1
		_FlowColor ("Flow Color1", Color) = (1, 1, 1, 1)		
		_FlowColor2("Flow Color2", Color) = (1, 1, 1, 1)		
		_FlowForceX  ("Flow Strength X", range (0,1)) = 0.1
		_FlowForceY  ("Flow Strength Y", range (0,1)) = 0.1
		_FlowUseUV2 ("FlowUseUV2", Float) = 0		
		_FlashTex("_FlashTex",2D) = "black"{}
		_FlashSpeed("FlashSpeed",Float) = 1
		_FlashColor("FlashColor", Color) = (1, 1, 1, 1)
		_LogicColor("LogicColor", Color) = (0, 0, 0, 0)
		_SSSColor("SSSColor",Color) = (0,0,0,0)
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
		uniform sampler2D _MaskTex;
		uniform float4 _EnvCube_HDR;
		UNITY_DECLARE_TEXCUBE(_EnvCube);
		uniform float _Glossiness;
		uniform float _Metallic;		
		uniform float _BumpScale;
		uniform float3 _DiffuseColor;				
		uniform float _SpecPower;
		uniform float _EnvDiffPower;
		uniform float _EnvSpecPower;
		uniform float _OA;
		uniform float4 _MainLightPos;
		uniform float3 _MainLightColor;
		uniform float4 _FillInLightPos;
		uniform float3 _FillInLightColor;
		uniform float4 _LogicColor;
		uniform float3 _SSSColor;
		
		uniform float _ISUI;
			
		struct v2f_base
		{
			float4 pos			: SV_POSITION;
			float4 uv			: TEXCOORD0;
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;
			float4 fl			: TEXCOORD4;
			float4 ml   		: TEXCOORD5;			
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

			float4 fl;
			GetWorldLightFormView(_FillInLightPos,fl);
			o.fl = fl;
			float4 ml;
			GetWorldLightFormView(_MainLightPos,ml);
			o.ml = ml;

			//纹理坐标	
			o.uv.xy = TRANSFORM_TEX( v.texcoord, _MainTex );
			o.uv.zw = GONBEST_CALC_FLOW_UV(v,  GONBEST_USE_FLOW_UV(v.texcoord,v.texcoord1));	
			return o;
		}

		fixed4 frag_base(v2f_base i) :COLOR
		{
			
			float4 color = _ISUI > 0.5 ? GONBEST_TEX_SAMPLE_LEVEL(_MainTex,i.uv.xy,0) : GONBEST_TEX_SAMPLE(_MainTex,i.uv.xy);
			float4 maskColor = tex2D(_MaskTex,i.uv.xy);
			color.rgb = lerp(color.rgb,_LogicColor.rgb,maskColor.b * _LogicColor.a);
			//颜色闪烁
			GONBEST_APPLY_FLASH(color, maskColor.g, i.uv.xy);	
			//处理颜色值
			GONBEST_APPLY_COLOR_MULTIPLIER(color)

			//应用AlphaTest
			GONBEST_APPLY_ALPHATEST(color)
			
			//自发光
			float3 emissive = _DiffuseColor * color;	

			//处理粗糙度和金属度
			float4 metaColor = tex2D(_MetallicTex,i.uv);
			float smoothness = _Glossiness * metaColor.g;
			float perceptualRoughness = max(0.08, 1 - smoothness);
			float rough = perceptualRoughness * perceptualRoughness;
			float meta = _Metallic * metaColor.r;
			//sss散射,只要颜色大于0.1就处理散射
			float sssdiff = max(0,step(0.1,metaColor.b)-0.1) * 1.111;
			//sss透射,只有颜色大于0.5才处理透射
			float sssrefract = max(0.5,metaColor.b) * 2 - 1;

			float oa = _OA;// * metaColor.b;
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
			float3 V = GetWorldViewDirWithUI(P.xyz, _ISUI);
			float3 R = reflect(-V,N);

			//主光
			float3 L = GBNormalizeSafe(i.ml.xyz);
			float3 H = GBNormalizeSafe(L+V);	
			float NoL = saturate(dot(N,L));
			float NoV = saturate(dot(N,V));
			float NoH = saturate(dot(N,H));
			float VoH = saturate(dot(V,H));
			float VoL = dot(V,L);

			//次光
			float3 L2 = GBNormalizeSafe(i.fl.xyz);
			float3 H2 = GBNormalizeSafe(L2+V);	
			float NoL2 = saturate(dot(N,L2));
			float NoH2 = saturate(dot(N,H2));
			float VoH2 = saturate(dot(V,H2));			
			float LoH2 = saturate(dot(L,H2));
			float VoL2 = dot(V,L2);

			//微平面阴影
			oa = oa * oa - 0.5;
			float microshadow= saturate(2 * oa + abs(NoL));
			float microshadow2= saturate(2 * oa + abs(NoL2));

			//漫反射
			float3 diff = i.ml.w *  _MainLightColor.rgb * NoL + _SSSColor * NoL * sssdiff;
			float3 diff2 = i.fl.w * _FillInLightColor.rgb * NoL2 + _SSSColor * NoL2 * sssdiff;

			//透射
			float3 refract1 = sssrefract * saturate(-VoL) * _SSSColor;
			float3 refract2 = sssrefract * saturate(-VoL2) * _SSSColor;

			//高光			
        	float GGX = GBGGXSpecularTerm(NoH, NoL,NoV, rough);
			float3 F = GBFresnelTermFastWithSpecGreen(specularColor,VoH);			
			float3 spec = GGX * F * diff;
			
			float GGX2 = GBGGXSpecularTerm(NoH2, NoL2,NoV, rough);  						
			float3 F2 = GBFresnelTermFastWithSpecGreen(specularColor,VoH2);						
			float3 spec2 = GGX2 * F2 * diff2;			

			float3 indirect = IndirectSpecular_Custom(UNITY_PASS_TEXCUBE(_EnvCube), _EnvCube_HDR,R,rough,meta) ;
			indirect *= SurfaceReductionTerm(rough,perceptualRoughness);
			indirect *= GBFresnelLerp(specularColor,GrazingTerm(smoothness,oneMinusReflectivity),NoV);
			indirect *= lerp(_EnvDiffPower,_EnvSpecPower, meta);			
			
			float4 Out = (float4)0;			
			Out.rgb = (diff * microshadow  + diff2 * microshadow2) * diffColor;
			Out.rgb += (spec + spec2) *specPowner ;
			Out.rgb += indirect;
			//这里求所有光线加在一起的强度
			float luminace = GBLuminance(Out.rgb);
			//玻璃的处理
			GONBEST_APPLY_GLASS(color,luminace);
			Out.rgb += emissive;
			Out.rgb += (refract1+refract2);
			Out.a = color.a;
			Out = saturate(Out);
			float4 orgCol = Out;			
			//流光
			GONBEST_APPLY_FLOW(i.uv.zw,Out,maskColor.r)
			//把高光项给到alpha
#if defined(_GONBEST_SPEC_ALPHA_ON)
			Out.a =  max(0, spec  * specPowner * meta) + GBLuminance(Out - orgCol);
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
				//#pragma multi_compile_fog	
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
				//#pragma multi_compile_fog	
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
				//#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,透明玻璃

			Name "COMMON&BLEND&GLASS"			
			Tags { "LightMode" = "ForwardBase" }			
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_GLASS_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
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
				//#pragma multi_compile_fog	
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
				//#pragma multi_compile_fog	
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
				//#pragma multi_compile_fog	
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
				//#pragma multi_compile_fog	
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
				//#pragma multi_compile_fog	
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
				//#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&BLINK"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_BLINK_ON
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON							
				//#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&BLINK"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
					
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_BLINK_ON
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON				
				//#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	


		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&BLINK"			
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
                #pragma multi_compile _GONBEST_FLOW_BLINK_ON										
				//#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLASH"			
			Tags { "LightMode" = "ForwardBase" }		
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC				
				#pragma multi_compile _GONBEST_FLASH_ON                				
				#pragma multi_compile _GONBEST_FLASH_TEX_ON
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
				//#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	

		/****************** DoubleFace ********************/
		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLOW&BACK"			
			Tags { "LightMode" = "ForwardBase" }			
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha		
			Cull Front	
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF
				#pragma multi_compile _GONBEST_FLASH_ON											
				//#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}	
	}
}