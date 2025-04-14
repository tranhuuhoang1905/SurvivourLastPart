/*===============================================================
Author:gzg
Date:2020-01-02
Desc: 运行时T4M的处理
===============================================================*/
Shader "Gonbest/PBR/T4MPBRHelper"
{
	Properties
	{	
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_BumpScale("_BumpScale",Range(0,2)) = 1  			//发现比率		
		_Glossiness("_Glossiness",Range(0,1)) = 0.2  //光滑度	
		_Metallic("_Metallic",Range(0,1)) = 0  //金属度
		_SpecularPower("_SpecularPower",Range(0,2)) = 1  //高亮强度
		_RainStength("_RainStength",Range(0,10)) = 0  			//雨的强度	
		_RainSpeed("_RainSpeed",Range(-2,2)) = 1	  			  			//雨的闪烁速度
		_DiffuseColor ("Diffuse Color", Color) = (0.7, 0.7, 0.7, 0.7)	
		_EnvPower("_EnvPower",float) = 0.1        //环境高亮的强度
		_EnvCube("Env Cube", Cube) = "white" {}
		_NoiseMap ("_NoiseMap", 2D) = "white" {}
		_NoiseBumpMap ("_NoiseBumpMap", 2D) = "white" {}
		_NoiseTiling("_NoiseTiling",float) = 5.2
		_NoisePower("_NoisePower",float) = 0.35	
		_RainFactor("_RainFactor",Range(0,1)) = 0  			//雨的影响因子
		_RainScale("_RainScale",float) = 1	  			  			  			//雨的地面闪烁碎裂程度
	}
	
	CGINCLUDE
		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
        #include "../Include/Utility/T4MUtilsCG.cginc"
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
		#include "../Include/Shadow/SceneShadowCG.cginc"

		uniform sampler2D _Control;
		uniform float4 _EnvCube_HDR;
		UNITY_DECLARE_TEXCUBE(_EnvCube);		
		uniform float _BumpScale = 1;		//发现比率
		uniform float _Glossiness = 0.8;  	 //光滑度
		uniform float _Metallic = 0;       	 //金属度
		uniform float _SpecularPower = 0.8;  //高亮亮度		
        uniform float _EnvPower;
        uniform float3 _DiffuseColor;
		
		struct v2f
		{
			float4 vertex 		: POSITION;			
			float4 uv			: TEXCOORD0;
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;			
			GONBEST_T4M_2_COORD(4)
			GONBEST_T4M_3_COORD(5)
			GONBEST_T4M_4_COORD(6)									
			GONBEST_FOG_COORDS(7)			
			GONBEST_SHADOW_COORDS(8)
			GONBEST_SCENCE_SHADOW_COORDS(9)
		};	
		
		//顶点处理程序
		v2f vert (appdata_full v)
		{
			v2f o = (v2f)0;
            float4 ppos,wpos;
			float3 wt,wn,wb;    
			GetVertexParameters(v.vertex, v.tangent, v.normal, ppos, wpos, wn, wt, wb);
			o.vertex = ppos;
			o.wt = float4(wt,wpos.x);        
			o.wb = float4(wb,wpos.y);
			o.wn = float4(wn,wpos.z);	
			
			o.uv.xy = v.texcoord.xy;
            o.uv.zw = GONBEST_CALC_LIGHTMAP_UV(v.texcoord1.xy);		

            GONBEST_TRANSFER_T4M_2(v,o)
			GONBEST_TRANSFER_T4M_3(v,o)
			GONBEST_TRANSFER_T4M_4(v,o)

			//阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);	
			GONBEST_SCENCE_TRANSFER_SHADOW_WPOS(o,wpos);	

			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.vertex, wpos);	
			return o;	
		}		
		fixed4 frag(v2f i) : COLOR
		{
			
			fixed4 splat_control = tex2D( _Control, i.uv.xy );
			fixed4 mainTex = fixed4(0,0,0,0);
			float4 NT = float4(0,0,0,0);
			GONBEST_APPLY_T4M_NORMAL_2(i,splat_control,mainTex,NT);
			GONBEST_APPLY_T4M_NORMAL_3(i,splat_control,mainTex,NT);
			GONBEST_APPLY_T4M_NORMAL_4(i,splat_control,mainTex,NT);
			//处理颜色值
			GONBEST_APPLY_COLOR_MULTIPLIER(mainTex)
			
            //发射光
            fixed3 emissive = _DiffuseColor *mainTex.xyz;	

            //处理粗糙度和金属度			
			half smoothness = _Glossiness;
			half perceptualRoughness = max(0.08, 1 - smoothness);
			half rough = perceptualRoughness * perceptualRoughness;
			half meta = _Metallic;
            half specPowner = _SpecularPower ;//* GONBEST_INV_PI;

            //根据能量守恒获取基础的散射光和高亮光颜色
			half oneMinusReflectivity;
			fixed3 diffColor,specularColor;
			GetDiffuseAndSpecular(mainTex.xyz, meta, diffColor, specularColor, oneMinusReflectivity);

            GONBEST_RAIN_NORMAL(NT,i.uv.xy);

            float3 N = GetWorldNormalFromBump(NT,_BumpScale,GBNormalizeSafe(i.wt.xyz),GBNormalizeSafe(i.wb.xyz),GBNormalizeSafe(i.wn.xyz));			
			float3 P = float3(i.wt.w, i.wb.w, i.wn.w);			
			float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
			float3 V = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - P.xyz); 
			float3 H = GBNormalizeSafe(L+V);	
            float3 R = reflect(-V,N);

            float NoH = max(0,dot(N,H));
            float NoL = max(0,dot(N,L));
			float LoH = max(0,dot(L,H));
            float NoV = max(0,dot(N,V));     
            float VoH = max(0,dot(H,V));   
            
            half GGX = GBGGXSpecularTermOptimize(NoH, LoH, rough);              
            half3 F = GBFresnelTermFastWithSpecGreen(specularColor,VoH);
			//ggx的高光分布
			fixed3 spec = GGX * specPowner * F;

            //间接光
			fixed3 indirectSpec = IndirectSpecular_Custom(UNITY_PASS_TEXCUBE(_EnvCube), _EnvCube_HDR,R,rough,meta) ;
			indirectSpec *= SurfaceReductionTerm(rough,perceptualRoughness);
			indirectSpec *= GBFresnelLerp(specularColor,GrazingTerm(smoothness,oneMinusReflectivity),NoV);
            indirectSpec *= _EnvPower;

            //间接散射光处理
			fixed3 indirectDiff = (fixed3)1;
			GONBEST_APPLY_LIGHTMAP_COLOR(i.uv.zw,indirectDiff);
			GONBEST_SCENCE_APPLY_SHADOW(i,indirectDiff);
			//阴影处理
 			//float3 luminance = gonbest_ColorSpaceLuminance.rgb * indirectDiff.rgb ;
            //float backShadowValue = step(0.8, luminance.r + luminance.g + luminance.b);
			//indirectDiff = lerp(float3(0,0,0.5),indirectDiff,backShadowValue) * shadowValue ;			
			indirectDiff *= GONBEST_DECODE_SHADOW_VALUE(i,P);		

            fixed4 outColor = (fixed4)0;
            outColor.rgb += (spec + diffColor) * NoL * _LightColor0.rgb;
            outColor.rgb += indirectSpec;
            outColor.rgb += emissive;      
            outColor.rgb *= indirectDiff;  
            
			            
            //噪音的光线波纹
			GONBEST_NOISE_LIGHT_LINE_APPLY(outColor,i.uv.xy);

			//对应模型雾的颜色
			GONBEST_APPLY_FOG(i, outColor.xyz);

			outColor.a = 0;
			
			return outColor;
            
		}		
	ENDCG

	SubShader
	{	
		Lighting Off
		ZWrite On
		Pass
		{	//两张纹理
			Name "TWO"	
            Tags { "LightMode" = "ForwardBase" }				
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_T4M_2_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}		
		Pass
		{	//三张纹理
			Name "THREE"		
            Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag		
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_T4M_3_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}		
		Pass
		{	//四张纹理
			Name "FOUR"		
            Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_T4M_4_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}		

	
		Pass
		{	//两张纹理
			Name "TWO&RAIN"	
            Tags { "LightMode" = "ForwardBase" }				
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_T4M_2_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}		
		Pass
		{	//三张纹理
			Name "THREE&RAIN"		
            Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag		
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_T4M_3_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}		
		Pass
		{	//四张纹理
			Name "FOUR&RAIN"		
            Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_RAIN_BUMP_ON _GONBEST_RAIN_BUMP_OFF
			#pragma multi_compile _GONBEST_T4M_4_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}	

		
		Pass
		{	//两张纹理
			Name "TWO&NOISELINE"	
            Tags { "LightMode" = "ForwardBase" }				
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_T4M_2_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}		
		Pass
		{	//三张纹理
			Name "THREE&NOISELINE"		
            Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag		
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_T4M_3_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}		
		Pass
		{	//四张纹理
			Name "FOUR&NOISELINE"		
            Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_NOISE_LIGHT_LINE_ON
			#pragma multi_compile _GONBEST_T4M_4_ON
			#pragma multi_compile _GONBEST_T4M_NORMAL_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile_fog
			#pragma target 3.0	
			ENDCG
		}	
			
	}
}