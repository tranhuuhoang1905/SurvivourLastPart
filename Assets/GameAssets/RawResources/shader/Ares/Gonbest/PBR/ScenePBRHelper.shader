/*===============================================================
Author:gzg
Date:2020-01-02
Desc: 场景的PBR处理
===============================================================*/
Shader "Gonbest/PBR/ScenePBRHelper"
{
	Properties
	{
	   	_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_BumpMap("Normal(RGB)",2D) = "black"{}		
		_BumpScale("_BumpScale",Range(0,2)) = 1  			//发现比率	
        _EnvPower("_EnvPower",float) = 0.1        //环境高亮的强度
		_EnvCube("Env Cube", Cube) = "white" {}
		_NoiseMap ("_NoiseMap", 2D) = "white" {}
		_NoiseBumpMap ("_NoiseBumpMap", 2D) = "white" {}
		_NoiseTiling("_NoiseTiling",float) = 5.2
		_NoisePower("_NoisePower",float) = 0.35		
		_MyShadowMap("Shadow map", 2D) = "black" {}      //阴影贴图
		_ShadowIntensity("Shadow Intensity",float) = 1  //阴影强度
		_ShadowFadeFactor("Shadow Fade Factor",float) = 0 //阴影被材质影响消隐的效果       
		_Glossiness("_Glossiness",Range(0,1)) = 0.2  //光滑度	
		_Metallic("_Metallic",Range(0,1)) = 0  //金属度
        _MetallicTex("Metallic(R)&Glossiness(G)&AO(B)",2D) = "white"{}  	//金属度	
		_SpecularPower("_SpecularPower",Range(0,2)) = 1  //高亮强度
		_RainStength("_RainStength",Range(0,10)) = 0  			//雨的强度	
		_RainSpeed("_RainSpeed",Range(-2,2)) = 1	  			 //雨的闪烁速度
        _DiffuseColor("EmissiveColor",Color) = (1,1,1,0)
		_ISUI("(> 0.5) is ui",float) = 0
	}
	CGINCLUDE				
        #include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
        #include "../Include/Utility/RainUtilsCG.cginc"
        #include "../Include/Utility/PixelUtilsCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
		#include "../Include/Shadow/SceneShadowCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"        
        #include "../Include/Base/EnergyCG.cginc"
        #include "../Include/Specular/GGXCG.cginc"
        #include "../Include/Base/FresnelCG.cginc"
        #include "../Include/Specular/BeckmannCG.cginc"		
		#include "../Include/Indirect/Lightmap&SHLightCG.cginc"

		uniform sampler2D _MainTex;
		uniform sampler2D _BumpMap;
		uniform float4 _EnvCube_HDR;
		UNITY_DECLARE_TEXCUBE(_EnvCube);	
        uniform sampler2D _MetallicTex;	
		uniform float4 _MainTex_ST;	
		uniform float _Glossiness = 0.8;  	 //光滑度
		uniform float _Metallic = 0;       	 //金属度
		uniform float _SpecularPower = 0.8;  //高亮亮度
		uniform float _BumpScale = 1;		//发现比率
        uniform float3 _DiffuseColor;
        uniform float _EnvPower;
		uniform float _ISUI;

		/*****************************带有lightmap的处理(分开了-_-!,这TM就是一个坑,lightmap处理好像不能放到一个宏判断中.)**********************************************/
		struct v2f_lit
		{
			float4 pos 		: POSITION;
			float4 uv 		: TEXCOORD0;			
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;
			GONBEST_FOG_COORDS(4)			
			GONBEST_SHADOW_COORDS(5)
			GONBEST_SH_COORDS(6)
			GONBEST_SCENCE_SHADOW_COORDS(7)
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};
		
		//通用功能的vert
		v2f_lit vert_lit(appdata_full v)
		{
			UNITY_SETUP_INSTANCE_ID(v);
			v2f_lit o = (v2f_lit)0;
            float4 ppos,wpos;
			float3 wt,wn,wb;    
			GetVertexParameters(v.vertex, v.tangent, v.normal, ppos, wpos, wn, wt, wb);
			o.pos = ppos;
			o.wt = float4(wt,wpos.x);        
			o.wb = float4(wb,wpos.y);
			o.wn = float4(wn,wpos.z);	
			
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
            o.uv.zw = GONBEST_CALC_LIGHTMAP_UV(v.texcoord1.xy);	
			GONBEST_TRANSFER_SH(o,wn,wpos);
			//阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);

			GONBEST_SCENCE_TRANSFER_SHADOW_WPOS(o,wpos);	
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.pos, wpos);	

			UNITY_TRANSFER_INSTANCE_ID(v, o);

			return o;
		}

		//通用的frag
		fixed4 frag_lit(v2f_lit i) : COLOR
		{
			UNITY_SETUP_INSTANCE_ID(i);
			fixed4 mainTex = GONBEST_TEX_SAMPLE(_MainTex, i.uv.xy);	
			//处理颜色值
			GONBEST_APPLY_COLOR_MULTIPLIER(mainTex)
			//应用AlphaTest
			GONBEST_APPLY_ALPHATEST(mainTex)

			fixed3 emissive = mainTex.xyz;//_DiffuseColor *mainTex.xyz;	

			//处理粗糙度和金属度
			fixed4 metaColor = tex2D(_MetallicTex,i.uv);
			half smoothness = _Glossiness * metaColor.g;
			half perceptualRoughness = max(0.08, 1 - smoothness);
			half rough = perceptualRoughness * perceptualRoughness;
			half meta = _Metallic * metaColor.r;
			half specPowner = _SpecularPower ;// * GONBEST_INV_PI;
			half ao = GBLerpOneTo (metaColor.b, 1);
			fixed isui = step(0.5, _ISUI);
			
            
			//根据能量守恒获取基础的散射光和高亮光颜色
			half oneMinusReflectivity;
			fixed3 diffColor,specularColor;
			GetDiffuseAndSpecular(mainTex.xyz, meta, diffColor, specularColor, oneMinusReflectivity);

			float4 NT = tex2D(_BumpMap,i.uv.xy);
            GONBEST_RAIN_NORMAL(NT,i.uv.xy)


            float3 N = GetWorldNormalFromBump(NT,_BumpScale,GBNormalizeSafe(i.wt.xyz),GBNormalizeSafe(i.wb.xyz),GBNormalizeSafe(i.wn.xyz));			
			float3 P = float3(i.wt.w, i.wb.w, i.wn.w);			
			float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
			float3 V = GBNormalizeSafe((_WorldSpaceCameraPos.xyz - P.xyz)); 
			float3 H = GBNormalizeSafe(L+V);	
            float3 R = reflect(-V,N);

            float NoH = max(0,dot(N,H));
            float NoL = max(0,dot(N,L));
            float NoV = max(0,dot(N,V));     
            float VoH = max(0,dot(H,V));     			
           
			half GGX = GBGGXSpecularTerm(NoH, NoL,NoV, rough);  
            half3 F = GBFresnelTermFastWithSpecGreen(specularColor,VoH);
			//ggx的高光分布
			fixed3 spec = GGX * F * specPowner ;
			 
            //间接光
			fixed3 indirectSpec = IndirectSpecular_Custom(UNITY_PASS_TEXCUBE(_EnvCube), _EnvCube_HDR,R,rough,meta) ;
			indirectSpec *= SurfaceReductionTerm(rough,perceptualRoughness);
			indirectSpec *=  GBFresnelLerp(specularColor,GrazingTerm(smoothness,oneMinusReflectivity),NoV);
            indirectSpec *= _EnvPower;

			//间接散射光处理
			fixed3 indirectDiff = (fixed3)1;
			GONBEST_APPLY_SH_COLOR(i,N,P,indirectDiff); 
			GONBEST_APPLY_LIGHTMAP_COLOR(i.uv.zw,indirectDiff);

			//这里判断是否使用了探针和Lightmap
			fixed useSHorLIGHTMAP = step(0.001,indirectDiff.x+indirectDiff.y+indirectDiff.z);
			indirectDiff = lerp((fixed3)1,indirectDiff,useSHorLIGHTMAP);
			
			GONBEST_SCENCE_APPLY_SHADOW(i,indirectDiff);
			//阴影处理	
			indirectDiff *= GONBEST_DECODE_SHADOW_VALUE(i,P);			

            fixed4 outColor = (fixed4)0;
            outColor.rgb += (spec + diffColor) * NoL * _LightColor0.rgb;
            outColor.rgb += indirectSpec * ao;
			//这里求所有光线加在一起的强度
			fixed luminace = GBLuminance(outColor.rgb);			

            outColor.rgb += emissive * ao;   
			outColor.a = mainTex.a;
			
			
			//间接光的处理
			outColor.rgb = lerp(indirectDiff * outColor.rgb, outColor.rgb, isui);   
            
			//玻璃的处理
			GONBEST_APPLY_GLASS(outColor,luminace)
			fixed4 em = outColor;
            //噪音的光线波纹
			GONBEST_NOISE_LIGHT_LINE_APPLY(outColor,i.uv.xy);
			em = outColor - em;
		    //对应模型雾的颜色			   
			GONBEST_APPLY_FOG_CHECK_UI(i, outColor.xyz,isui);
			//把高光项给到alpha
#if defined(_GONBEST_SPEC_ALPHA_ON)
			outColor.a = max(0 , spec * meta * smoothness * indirectDiff * NoL);
#endif

			return outColor;
		}
		/***************************************************************************/
	ENDCG
	
	SubShader
	{ 
		ZTest Less		
		ZWrite On
		Pass
		{  
			//这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF 	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON 
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF 
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN			
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma target 3.0	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON	
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						         
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma target 3.0
			ENDCG
		}

		
		
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF		
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma target 3.0			
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF		
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

		
		
		Pass
		{  //这个Pass使用lightmap和使用阴影 -- 这里使用Alpha贴图
			Name "LIGHTMAP&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影-- 这里使用Alpha贴图
			Name "NOLIGHTMAP&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF		
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

	
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

	
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF		
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

	
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest		
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF	
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog
			#pragma multi_compile_instancing			
			#pragma target 3.0
			ENDCG
		}

	
		Pass
		{  
			//这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST&ALPHATEX&SUNNY"
			Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF             		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON 
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma target 3.0	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST&ALPHATEX&SUNNY"
			Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON	
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma target 3.0
			ENDCG
		}
		
	

		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND&ALPHATEX&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF				
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma target 3.0			
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND&ALPHATEX&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest					            
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

	
		
		Pass
		{  //这个Pass使用lightmap和使用阴影 -- 这里使用Alpha贴图
			Name "LIGHTMAP&ALPHATEX&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            	
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF					
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影-- 这里使用Alpha贴图
			Name "NOLIGHTMAP&ALPHATEX&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF				
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma multi_compile_instancing
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON					
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON					
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

		
		Pass
		{  //这个Pass使用lightmap和使用阴影,双面
			Name "LIGHTMAP&ALPHATEST&SUNNY&DOUBLEFACE"
			Tags { "LightMode" = "ForwardBase" }
			Cull OFF
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF				
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影,双面
			Name "NOLIGHTMAP&ALPHATEST&SUNNY&DOUBLEFACE"
			Tags { "LightMode" = "ForwardBase" }
			Cull OFF
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON					
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON					
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

	
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            				
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON		
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest            							
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&SUNNY"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            				
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&SUNNY"
			Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest            
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

		Pass
		{  
			//这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST&ALPHATEX&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF             		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON 
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma target 3.0	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST&ALPHATEX&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON	
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma target 3.0
			ENDCG
		}
		
	

		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND&ALPHATEX&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF				
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma target 3.0			
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND&ALPHATEX&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest					            
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}

	
		
		Pass
		{  //这个Pass使用lightmap和使用阴影 -- 这里使用Alpha贴图
			Name "LIGHTMAP&ALPHATEX&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            	
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF					
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影-- 这里使用Alpha贴图
			Name "NOLIGHTMAP&ALPHATEX&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}

		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF				
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON					
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON					
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}

		
		Pass
		{  //这个Pass使用lightmap和使用阴影,双面
			Name "LIGHTMAP&ALPHATEST&NOISELIGHTLINE&DOUBLEFACE"
			Tags { "LightMode" = "ForwardBase" }
			Cull OFF
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF				
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影,双面
			Name "NOLIGHTMAP&ALPHATEST&NOISELIGHTLINE&DOUBLEFACE"
			Tags { "LightMode" = "ForwardBase" }
			Cull OFF
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON					
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON					
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}

	
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            				
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON		
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest            							
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            				
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog			
			#pragma multi_compile_instancing
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&NOISELIGHTLINE"
			Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest            
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			#pragma target 3.0
			ENDCG
		}
	
	}
}