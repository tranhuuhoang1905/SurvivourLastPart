/*===============================================================
Author:gzg
Date:2020-02-12
Desc:这个Shader是用于只展示lightmap的渲染,
=================================================================*/
Shader "Gonbest/FallBack/FBWithLightmap"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex("Albedo", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_BumpMap("Normal(RGB)",2D) = "blue"{}		
		_BumpScale("BumpScale",Range(0,2)) = 1  			//发现比率
		_Glossiness("Glossiness",Range(0,1)) = 0.9  //光滑度	
		_Metallic("Metallic",Range(0,1)) = 0  //金属度
        _MetallicTex("Glossiness(A)&Metallic(R)&AO(G)&Emission(B)",2D) = "white"{}  	//金属度	
		_SpecularPower("SpecularPower",Range(0,2)) = 1  //高亮强度
        _EnvDiffPower("EnvDiffPower",Range(0,2)) = 1        //环境高亮的强度					
        _EnvSpecPower("EnvSpecPower",Range(0,2)) = 1        //环境高亮的强度	
        _EmissionColor("EmissiveColor",Color) = (0,0,0,0)
        _NoiseMap ("NoiseMap", 2D) = "white" {}
		_NoiseBumpMap ("NoiseBumpMap", 2D) = "white" {}
		_NoiseTiling("NoiseTiling",float) = 5.2
		_NoisePower("NoisePower",float) = 0.35
        _RainStength("RainStength",Range(0,10)) = 0  			//雨的强度	
		_RainSpeed("RainSpeed",Range(-2,2)) = 1	  			 //雨的闪烁速度
        _MyShadowMap("Shadow map", 2D) = "black" {}      //阴影贴图
		_ShadowIntensity("Shadow Intensity",float) = 1  //阴影强度
		_ShadowFadeFactor("Shadow Fade Factor",float) = 0 //阴影被材质影响消隐的效果   
        _ShadowRange("ShadowRange(阴影范围)", Range(0 , 1)) = 0        
		_ShadowPower("ShadowPower(阴影强度)", Range(0 , 1)) = 0.8
        _ShadowSmooth("ShadowSmooth(阴影边缘锐化程度)", Range(0 , 1)) = 0.8    
        _ShadowTex1("ShadowTex1", 2D)  = "black" {}

	}
	CGINCLUDE				
        #include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
        #include "../Include/Utility/RainUtilsCG.cginc"
        #include "../Include/Utility/PixelUtilsCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"        
        #include "../Include/Base/EnergyCG.cginc"
        #include "../Include/Specular/GGXCG.cginc"
        #include "../Include/Base/FresnelCG.cginc"
        #include "../Include/Specular/BeckmannCG.cginc"		
		#include "../Include/Indirect/Lightmap&SHLightCG.cginc"
        #include "../Include/Base/RampCG.cginc"

		uniform sampler2D _MainTex;
		uniform sampler2D _BumpMap;		
        uniform sampler2D _MetallicTex;	
		uniform float4 _MainTex_ST;	
		uniform float _Glossiness = 0.8;  	 //光滑度
		uniform float _Metallic = 0;       	 //金属度
		uniform float _SpecularPower = 1;  //高亮亮度
		uniform float _BumpScale = 1;		//发现比率
        uniform float3 _EmissionColor;
        uniform float _EnvDiffPower;
        uniform float _EnvSpecPower;
        uniform float _ShadowRange;
        uniform float _ShadowPower;
        uniform float _ShadowSmooth;
        uniform sampler2D _ShadowTex1;

		/*****************************带有lightmap的处理(分开了-_-!,这TM就是一个坑,lightmap处理好像不能放到一个宏判断中.)**********************************************/
		struct v2f_lit
		{
			float4 pos 		    : POSITION;
			float4 uv 		    : TEXCOORD0;			
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;
			GONBEST_FOG_COORDS(4)			
			GONBEST_SHADOW_COORDS(5)
			GONBEST_INDIRECT_DIFFUSE_COORDS(6)
		};
		
		//通用功能的vert
		v2f_lit vert_lit(appdata_full v)
		{
			v2f_lit o = (v2f_lit)0;
            float4 ppos,wpos;
			float3 wt,wn,wb;    
			GetVertexParameters(v.vertex, v.tangent, v.normal, ppos, wpos, wn, wt, wb);
			o.pos = ppos;
			o.wt = float4(wt,wpos.x);        
			o.wb = float4(wb,wpos.y);
			o.wn = float4(wn,wpos.z);	
			
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);           
			GONBEST_TRANSFER_INDIRECT_DIFFUSE(o,wn,wpos,v.texcoord1.xy);
			
			//阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);			
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.pos, wpos);	

			return o;
		}
       
		//通用的frag
		fixed4 frag_lit(v2f_lit i) : COLOR
		{
			//间接散射光处理
			float3 indirectDiff = (float3)1;
            float3 P = float3(i.wt.z,i.wb.z,i.wn.z);
            float3 N = GBNormalizeSafe(i.wn);
			GONBEST_APPLY_INDIRECT_DIFFUSE_COLOR(i,N,P,indirectDiff); 
            indirectDiff *= GONBEST_DECODE_SHADOW_VALUE(i,P);	
            float4 outColor = float4 (indirectDiff,1);                     
			//对应模型雾的颜色
			GONBEST_APPLY_FOG(i, outColor.xyz);		  
			return  outColor;//float4(indirectDiff,1);
		}
		/***************************************************************************/
	ENDCG
	
	SubShader
	{ 
        Tags { "RenderType"="Opaque" }
		ZTest Less		
		ZWrite On
		Pass
		{              
			//这个Pass使用lightmap和使用阴影			
			Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest					
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON						
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF 
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON			
			#pragma multi_compile _GONBEST_SHADOW_ON				
			#pragma multi_compile_fog	
			#pragma target 3.0	
			ENDCG
		}
	}
}