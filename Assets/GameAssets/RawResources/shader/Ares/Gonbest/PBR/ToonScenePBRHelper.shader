//这个Shader是用来为了为其他Shader提供一些特殊的Pass
Shader "Gonbest/PBR/ToonScenePBRHelper"
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
			float4 pos 		: POSITION;
			float4 uv 		: TEXCOORD0;			
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
			fixed4 mainTex = GONBEST_TEX_SAMPLE(_MainTex, i.uv.xy);	
			//处理颜色值
			GONBEST_APPLY_COLOR_MULTIPLIER(mainTex)
			//应用AlphaTest
			GONBEST_APPLY_ALPHATEST(mainTex)

			

			//处理粗糙度和金属度
			float4 metaColor = tex2D(_MetallicTex,i.uv);
			float smoothness = _Glossiness * metaColor.a;
			float perceptualRoughness = 1 - smoothness;
			float rough = perceptualRoughness * perceptualRoughness;
			float meta = _Metallic * metaColor.r;
			float specPowner = _SpecularPower ;// * GONBEST_INV_PI;
			float ao = GBLerpOneTo (metaColor.b, 1);
            float3 emissive = _EmissionColor *mainTex.xyz * metaColor.g;	
			
            
			//根据能量守恒获取基础的散射光和高亮光颜色
			half oneMinusReflectivity;
			float3 diffColor,specularColor;
			GetDiffuseAndSpecular(mainTex.xyz, meta, diffColor, specularColor, oneMinusReflectivity);

			float4 NT = tex2D(_BumpMap,i.uv.xy);
            GONBEST_RAIN_NORMAL(NT,i.uv.xy)
            float3 N = GetWorldNormalFromBump(NT,_BumpScale,GBNormalizeSafe(i.wt.xyz),GBNormalizeSafe(i.wb.xyz),GBNormalizeSafe(i.wn.xyz));			
			float3 P = float3(i.wt.w, i.wb.w, i.wn.w);			
			float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
			float3 V = GBNormalizeSafe((_WorldSpaceCameraPos.xyz - P.xyz)); 
			float3 H = GBNormalizeSafe(L+V);	
            float3 R = reflect(-V,N);

            float NoH = saturate(dot(N,H));
            float NoL = saturate(dot(N,L));
            float NoV = saturate(dot(N,V));     
            float VoH = saturate(dot(H,V));  

            //diff
            float3 diff = NoL * _LightColor0.rgb;
			
			//ggx的高光分布
			float GGX = GBGGXSpecularTerm(NoH, NoL,NoV, rough);  
            float3 F = GBFresnelTermFastWithSpecGreen(specularColor,VoH);			
			fixed3 spec = GGX * F * specPowner ;
            spec = spec * NoL * _LightColor0.rgb;
			 
            //间接高光            
            float3 indirectSpec = IndirectSpecular_Unity (P,N,V,L,R,NoL,smoothness,specularColor,_LightColor0.rgb);
			indirectSpec *= SurfaceReductionTerm(rough,perceptualRoughness);
			indirectSpec *= GBFresnelLerp(specularColor,GrazingTerm(smoothness,oneMinusReflectivity),NoV);
            indirectSpec *= _EnvSpecPower;
            indirectSpec *= ao;

            specularColor = spec + indirectSpec;

           
			//间接散射光处理
			float3 indirectDiff = (float3)1;
			GONBEST_APPLY_INDIRECT_DIFFUSE_COLOR(i,N,P,indirectDiff); 

            indirectDiff *= GONBEST_DECODE_SHADOW_VALUE(i,P);	
			indirectDiff *= ao;

            diffColor *= (lerp(1,indirectDiff,_EnvDiffPower) + diff);

            float4 outColor = float4 (diffColor + specularColor + emissive,mainTex.a);         
            
            
			//对应模型雾的颜色
			//GONBEST_APPLY_FOG(i, outColor.xyz);		  

			return  outColor;//float4(indirectDiff,1);
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
			Name "INDIRECT&ALPHATEST&ALPHATEX"
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
			//#pragma multi_compile SHADOWS_SCREEN			
			#pragma multi_compile_fog	
			#pragma target 3.0	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHATEST&ALPHATEX"
			//Tags { "LightMode" = "ForwardBase" }	
			
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT&ALPHABLEND&ALPHATEX"
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
			#pragma target 3.0			
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHABLEND&ALPHATEX"
			//Tags { "LightMode" = "ForwardBase" }	
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
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{  //这个Pass使用lightmap和使用阴影 -- 这里使用Alpha贴图
			Name "INDIRECT&ALPHATEX"
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影-- 这里使用Alpha贴图
			Name "NOINDIRECT&ALPHATEX"
			//Tags { "LightMode" = "ForwardBase" }	
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
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT&ALPHATEST"
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHATEST"
			//Tags { "LightMode" = "ForwardBase" }	
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}


		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT&ALPHABLEND"
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
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHABLEND"
			//Tags { "LightMode" = "ForwardBase" }	
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
			#pragma target 3.0
			ENDCG
		}

		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT"
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT"
			//Tags { "LightMode" = "ForwardBase" }	
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
			#pragma target 3.0
			ENDCG
		}

		
		Pass
		{  
			//这个Pass使用lightmap和使用阴影
			Name "INDIRECT&ALPHATEST&ALPHATEX&SUNNY"
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma target 3.0	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHATEST&ALPHATEX&SUNNY"
			//Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON	
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog	
			#pragma target 3.0
			ENDCG
		}
		

		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT&ALPHABLEND&ALPHATEX&SUNNY"
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
			#pragma target 3.0			
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHABLEND&ALPHATEX&SUNNY"
			//Tags { "LightMode" = "ForwardBase" }
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
			#pragma target 3.0
			ENDCG
		}


		Pass
		{  //这个Pass使用lightmap和使用阴影 -- 这里使用Alpha贴图
			Name "INDIRECT&ALPHATEX&SUNNY"
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影-- 这里使用Alpha贴图
			Name "NOINDIRECT&ALPHATEX&SUNNY"
			//Tags { "LightMode" = "ForwardBase" }
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
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT&ALPHATEST&SUNNY"
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHATEST&SUNNY"
			//Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	            		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON					
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON					
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF						
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}

		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT&ALPHABLEND&SUNNY"
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
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&ALPHABLEND&SUNNY"
			//Tags { "LightMode" = "ForwardBase" }
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
			#pragma target 3.0
			ENDCG
		}


		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "INDIRECT&SUNNY"
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
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOINDIRECT&SUNNY"
			//Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest            
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF							
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			//#pragma multi_compile SHADOWS_SCREEN
			#pragma multi_compile_fog			
			#pragma target 3.0
			ENDCG
		}

	}
}