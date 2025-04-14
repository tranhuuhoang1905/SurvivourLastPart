//这个Shader是用来为了为其他Shader提供一些特殊的Pass
Shader "Gonbest/Experiment/SkinPassHelper_Normal"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_ColorMultiplier("Color Multipler",Range(0,2)) = 1
		_MainTex ("Base (RGB)", 2D) = "white" {}				
		_MaskTex ("Mask", 2D) = "white" {}			
		_BumpMap ("_BumpMap", 2D) = "white" {}				
		_BumpScale("_BumpScale",float) = 1
		_DetailBumpMap ("_DetailBumpMap", 2D) = "white" {}	
		_DetailUVScale("_DetailUVScale",float) = 10
		_LutMapTex ("_LutMapTex", 2D) = "white" {}
		_SunColor("_SunColor",Color) = (1.52,1.21,0.777,0)
		_SSSColor("_cSSSColor",Color) = (0.25,0,0,1)
		_SSSIntensity("_cSSSIntensity",Range(0,1)) = 1		
		_PoreIntensity("_PoreIntensity",Range(0,1)) = 0.550
		_RoughnessOffset1("RoughnessOffset1",Range(0,1)) = 1
		_RoughnessOffset2("RoughnessOffset2",Range(0,1)) = 1
		_EnvInfo("_EnvInfo",vector)=(0,0,0,0)
		
	}

	CGINCLUDE		
		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Utility/WidgetUtilsCG.cginc"	
		#include "../Include/Base/NormalCG.cginc"		

		uniform sampler2D _MainTex;	
		uniform sampler2D _BumpMap;		
		uniform sampler2D _DetailBumpMap;		
		uniform half4 _MainTex_ST;
		uniform sampler2D _DetailNormalTex;
		uniform sampler2D _LutMapTex;
		uniform float _DetailUVScale;
		uniform float3 _SSSColor;
		uniform float _SSSIntensity;
		uniform float _PoreIntensity;
		uniform float _RoughnessOffset1;
		uniform float _RoughnessOffset2;
		uniform float _BumpScale;
		uniform float4 _EnvInfo;
			
		struct v2f_base
		{
			float4 pos	: SV_POSITION;
			half4 uv	: TEXCOORD0;
			float4 _wt 			: TEXCOORD1;
			float4 _wb 			: TEXCOORD2;
			float4 _wn 			: TEXCOORD3;
		};

		v2f_base vert_base(appdata_full v)
		{
			v2f_base o =(v2f_base)0;					
			o.pos = UnityObjectToClipPos( v.vertex );
			o.uv.xy = TRANSFORM_TEX( v.texcoord, _MainTex );
			float3 wpos = mul(unity_ObjectToWorld,v.vertex).xyz;
			o._wn.xyz = GBNormalizeSafe(mul(float4(v.normal,0),unity_WorldToObject).xyz);
			o._wt.xyz = GBNormalizeSafe((mul(unity_ObjectToWorld,float4(v.tangent.xyz,1)))/v.tangent.w);
			o._wb.xyz = GBNormalizeSafe(cross(o._wn,o._wt));
			o._wt.w = wpos.x;
			o._wb.w = wpos.y;
			o._wn.w = wpos.z;		
			return o;
		}

		
		/******************WrapLight的算法*************************/
		//返回漫反射的wrap信息
		#define FUNCELL_DIFFUSE_WRAP_LIGHT(nol,w) max(0,nol + w)/(1+w)

		//通过漫反射来查询纹理--也是wraplight的一种方式
		#define FUNCELL_DIFFUSE_WRAP_LIGHT_LUT(nol,curvature) tex2D(_LutMapTex , half2(0.5*nol+0.5 ,curvature))

		/**************************************************/			

		/******************折射的算法***********************/

		#define FUNCELL_DIFFUSE_REFRACTION(bol,litIrr,thick,ssscolor) saturate(0.6 + BoL) * saturate(0.6 + BoL) * litIrr * thick * ssscolor;

		/**************************************************/


		//SSS散射计算
		half3 SSSDiffuse(/*法线和光线的夹角*/half NoL, /*细节法线与光线的夹角*/half DoL, /*BentNormal与光线的夹角*/half FreeBoL, 
							/*光强*/half3 SunIrradiance, /*环境光强*/half3 GIIrradiance, 
							/*皮肤厚度*/half Thickness, /*曲率半径*/half Curvature, 
							/*SSS和原始散射混合参数*/half SSSBlendValue, /*SSS强度*/half SSSIntensity, /*SSS颜色*/half3 SSSColor)
		{

			//折射光 --- 皮肤比较薄的地方,光线会投射过来,其中0.6是经验值.
			half3 RefractionNoL = saturate(0.6 + FreeBoL);
			RefractionNoL *= RefractionNoL;
			half3 RefractionIrradiance = (SunIrradiance + GIIrradiance) * Thickness * SSSColor * RefractionNoL;				
			
			//x=为与法线的夹角,y为曲率				
			half3 SSS_Lut1 = FUNCELL_DIFFUSE_WRAP_LIGHT_LUT(NoL,SSSIntensity*Curvature);
			SSS_Lut1.rgb *= SSS_Lut1.rgb;
			
			//细节法线的处理--毛孔	
			half LutUV2 = (1 + DoL-NoL);
			LutUV2 = lerp(LutUV2, LutUV2 * LutUV2, (1-SSSIntensity));
			
			//SSS直射光的辐射度
			half3 SSS_SunIrradiance = lerp(LutUV2 * SSS_Lut1.rgb, NoL, SSSBlendValue) * SunIrradiance;
			
			return RefractionIrradiance + SSS_SunIrradiance + GIIrradiance;
			
		}

				//这个是皮肤的获取粗糙度的函数
		half GetRoughness_Human(in half Smoothness,in float3 N)
		{
			half Roughness = max(1-Smoothness,0.03);
			//这里应该是判断是否使用EnvInfo
			half rain= _EnvInfo.x * 0.5;
			rain = 1 - rain* saturate(3*N.y + 0.2 + 0.1*rain);
			return clamp( rain * Roughness, 0.05, 1);
		}


		//GGX的正态分布函数
		inline float GGX_D(in float Roughness/*粗糙度*/, float NoH/*N和H的dot*/)
		{
			float m2= Roughness*Roughness + 0.0002;
			m2 *= m2;		 		 
			float D=(NoH*m2 - NoH) * NoH + 1;				 
			D = D*D + 1e-06;
			return 0.25 * m2 / D;
		}

		//两层粗糙度不同的高光混合
		half3 SpecBRDFPbrWithTwoLayer(/*粗糙度偏移*/in half RoughnessOffset1, /*粗糙度偏移*/in half RoughnessOffset2, /*原始粗糙度*/in half Roughness, 
							/*高光的遮罩值*/in half specMask1, /*高光的颜色*/in half3 SkinSpec_color1, /*高光的遮罩值*/in half specMask2 , /*高光的颜色*/in half3 SkinSpec_color2, 
							/*漫反射值*/in half NoL,/*细节法线与半角向量*/ in half DoH, /*视线与半角向量*/in half VoH ,/*fresnel菲涅尔值F0*/in half F0 , 
							/*光照强度*/in half3 LitIrradiance,
							/*两个粗糙度混合值*/in half mixValue )
		{
			half3 SpecularMask1 = specMask1 * SkinSpec_color1;
			half3 SpecularMask2 = specMask2 * SkinSpec_color2;
				
			half Roughness1 = lerp(1 - (1-Roughness) * RoughnessOffset1,  Roughness, mixValue);	
			half Roughness2 = lerp(Roughness * RoughnessOffset2,  Roughness, mixValue);
			
			half D1 = GGX_D(Roughness1,DoH) * 0.3183; // 0.3183 = 1 / 3.14159265;
			half D2 = GGX_D(Roughness2,DoH) * 0.3183; // 0.3183 = 1 / 3.14159265;
			
			//这里是利用的UE4的Fresnel的Schlick近似公式 Pow((1-vh),5)
			//F = F0+ (1-F0) * exp2((-5.55473 * VoH - 6.98316) * VoH)
			half FG = F0 + (1 - F0) * exp2((-5.55473 * VoH - 6.98316) * VoH);
			//float3 FG = SpecularColor + (saturate(50*Specular.g) - SpecularColor) * exp2((-5.55473 * VoH - 6.98316) * VoH);
			
			half3 BRDF1 = D1*FG;
			half3 BRDF2 = D2*FG;
				
			half3 brdfParam = LitIrradiance * NoL * 2;
			half3 SpecRadiance1 = BRDF1*brdfParam;
			half3 SpecRadiance = BRDF1*brdfParam*SpecularMask1 + brdfParam*BRDF2 * SpecularMask2;			
			
			return lerp(SpecRadiance,SpecRadiance1 * 0.5,mixValue);

		};


		fixed4 frag_base(v2f_base i) :COLOR
		{
			fixed4 color = GONBEST_TEX_SAMPLE(_MainTex,i.uv) ;		
			GONBEST_SAMPLE_MASK(i);
			
			float smoothness = color.r;
			//皮肤的颜色float3(1.35,1.2,1.3)
			color.rgb = lerp(color.rgb,  color.rgb * float3(1.35,1.2,1.3) , GONBEST_MASK_VALUE_4);			
			GONBEST_APPLY_COLOR_MULTIPLIER(color);

			float4 normal = tex2D(_BumpMap,i.uv);
			half3 TN = GBUnpackScaleNormal(normal,_BumpScale);
			float3 N = GBNormalizeSafe(float3(GBNormalizeSafe(i._wt.xyz) * TN.x + GBNormalizeSafe(i._wb.xyz) * TN.y + GBNormalizeSafe(i._wn.xyz) * TN.z));
			float3 RN = N;//RippleNormal(N, i.uv.xy,_RainStength );
			float3 P = float3(i._wt.w, i._wb.w, i._wn.w);			
			float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
			float3 V = GBNormalizeSafe((_WorldSpaceCameraPos.xyz - P.xyz)); 
			float3 H = GBNormalizeSafe(L+V);	

			float freendl = dot(N,L);
			float ndl = saturate(freendl);
			float vdh = saturate(dot(V,H));
			
			//细节法线
			float4 DetailValue = tex2D(_DetailBumpMap, i.uv.zw * _DetailUVScale ); 
			float3 temp = float3(DetailValue.b * 2 - 1,1,0);
			temp *= 0.2;
			temp = GBNormalizeSafe(TN.xyz + temp * _PoreIntensity);			
			float3 DetailNormal = GBNormalizeSafe(float3(GBNormalizeSafe(i._wt.xyz) * temp.x + GBNormalizeSafe(i._wb.xyz) * temp.y + GBNormalizeSafe(i._wn.xyz) * temp.z));
			
			//曲率
			float curvature = GONBEST_MASK_VALUE_1; //saturate( length(fwidth(GONBEST_F_VAL_N))/length(fwidth(GONBEST_F_VAL_WP)) * _Curvature);
			//皮肤厚薄
			float thickness = GONBEST_MASK_VALUE_2;
			//ao信息
			float ao = GONBEST_MASK_VALUE_3 ;
			//混合
			float mixval = 1-GONBEST_MASK_VALUE_4;
			
			
			float3 diff = SSSDiffuse(ndl, saturate(dot(L,DetailNormal)),freendl,  
										_LightColor0 * 2, ao * _LightColor0.xyz,
										thickness,curvature, mixval,
										_SSSIntensity, _SSSColor);
			
			float3 spec = SpecBRDFPbrWithTwoLayer(_RoughnessOffset1, _RoughnessOffset2, GetRoughness_Human(smoothness,N),
													DetailValue.r, float3(1,0.3,0),  DetailValue.g, float3(0,0.2,0.5),
													ndl, saturate(dot(DetailNormal,H)) , vdh, 0.04,
													_LightColor0,
													mixval
													);			
			
			color.rgb = spec + diff * color;
			return color;
		}
    ENDCG	
	
	SubShader
	{ 
		ZTest LEqual
	    Lighting Off
		ZWrite On				
		Pass
		{
			//一个最基本的通用型Pass,非透明
			Name "FULL"					
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base						
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
				#pragma multi_compile _GONBEST_MASK_ON
				#pragma multi_compile_fog	
				#pragma target 3.0
			ENDCG
		}		
	}
}