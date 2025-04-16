/*===============================================================
Author:gzg
Date:2020-01-02
Desc: 新头发处理
===============================================================*/
Shader "Gonbest/PBR/NewHairPBRHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex ("RG:各项异性光偏移&B:环境遮挡&A:透明度", 2D) = "white" {}	
		_Cutoff ("CutOff", Range(0,1)) = 0.5
		_SpecularShift("各项异性光偏移参数", Range( -1 , 1)) = -1
		_SpecularPower1("各项异性光强度1",Range(0,1000)) = 300			
		_SpecularColor1("各项异性光颜色1", Color) = (0.5,0.5,0.5,1)		
		_SpecularPower2 ("各项异性光强度2", Range(0, 100)) = 40		
		_SpecularColor2("各项异性光颜色2", Color) = (0.5,0.5,0.5,1)
		_SpecularRange("各项异性光范围", Range( 0 , 5)) = 0	

		_PBRInstensity("各向异性影响值", Range( 0 , 1)) = 0.5		
		_EnvDiffPower("间接散射光",Range(0,4)) = 1
		_EnvSpecPower("间接高光",Range(0,4)) = 1
		_EnvCube("环境光", Cube) = "grey" {}	
		_BumpScale("法线比率",Range(0,2)) = 1  			//发现比率				
		_BumpMap("法线贴图",2D) = "black"{}				
		_MainLightPos("主光方向",Vector) = (0,0,0,1)
		_MainLightColor("主光颜色",Color) = (1,1,1,1)
		
		_ISUI("(> 0.5) is ui",float) = 0
	}
	CGINCLUDE

		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Specular/KajiyaKayCG.cginc"
		#include "../Include/Utility/WidgetUtilsCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/PixelUtilsCG.cginc"
		#include "../Include/Base/EnergyCG.cginc"
		#include "../Include/Base/NormalCG.cginc"		
		#include "../Include/Base/FresnelCG.cginc"	
		#include "../Include/Indirect/Lightmap&SHLightCG.cginc"
		#include "../Include/Specular/BlinnPhongCG.cginc"
		
		
		uniform sampler2D _MainTex;
		uniform half4 _MainTex_ST;
		uniform float _SpecularShift;
		uniform float _SpecularRange;
		uniform half _SpecularPower1;	
		uniform fixed3 _SpecularColor1;		
		uniform half _SpecularPower2;			
		uniform fixed3 _SpecularColor2;
		

		uniform sampler2D _BumpMap;						
		uniform half _BumpScale;		
		uniform float4 _EnvCube_HDR;
		UNITY_DECLARE_TEXCUBE(_EnvCube);		
		uniform float _EnvDiffPower;
		uniform float _EnvSpecPower;
		uniform float4 _MainLightPos;
		uniform float3 _MainLightColor;	
		uniform float _PBRInstensity;
		uniform float _ISUI;
			
		
		struct v2f_base
		{
			float4 pos	: SV_POSITION;
			half4 uv	: TEXCOORD0;
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;			
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
			o.uv.xy = TRANSFORM_TEX( v.texcoord, _MainTex );			
			float4 ml;
			GetWorldLightFormView(_MainLightPos,ml);
			o.ml = ml;
			return o;
		}		
		
			//写深度的处理
		fixed4 frag_write_z_a(v2f_base i): COLOR
		{			
			fixed4 color = tex2D(_MainTex,i.uv) ;		
			GONBEST_APPLY_ALPHATEST(color)
			return color;
		}

		//基础处理
		fixed4 frag_base(v2f_base i): COLOR
		{			
			fixed4 color = float4(1,1,1,1) ;
			
			GONBEST_APPLY_COLOR_MULTIPLIER(color);					

			float3 T = GBNormalizeSafe(i.wt.xyz);
			float3 B = GBNormalizeSafe(i.wb.xyz);
			float3 WN = GBNormalizeSafe(i.wn.xyz);
			//处理法线
			float4 NT = tex2D(_BumpMap,i.uv.xy);
			float3 N = GetWorldNormalFromBump(NT,_BumpScale,GBNormalizeSafe(i.wt.xyz),GBNormalizeSafe(i.wb.xyz),GBNormalizeSafe(i.wn.xyz));			
			float3 P = float3(i.wt.w, i.wb.w, i.wn.w);

			//视线
			float3 V = GetWorldViewDirWithUI(P.xyz, _ISUI);
			float3 R = reflect(-V,N);

			
			float3 L = GBNormalizeSafe(i.ml.xyz);			
			float3 H = GBNormalizeSafe(L+V);

			float NoL = saturate(dot(N,L));
			float NoV = saturate(dot(N,V));
			float NoH = saturate(dot(N,H));
			float VoH = saturate(dot(V,H));
			float VoL = dot(V,L);		
			
			//金属
			float meta = 0;
			//光滑度
			float smoothness = 0.2;
			float perceptualRoughness = max(0.08, 1 - smoothness);
			float rough = perceptualRoughness * perceptualRoughness;

			
			//根据能量守恒获取基础的散射光和高亮光颜色
			half oneMinusReflectivity;
			float3 diffColor,specularColor;
			GetDiffuseAndSpecular(color, meta, diffColor, specularColor, oneMinusReflectivity);

			//间接高光
			float3 indirectSpec = IndirectSpecular_Custom (UNITY_PASS_TEXCUBE(_EnvCube), _EnvCube_HDR,P,N,V,L,R,NoL,smoothness,specularColor,_MainLightColor.rgb);
			indirectSpec *= SurfaceReductionTerm(rough,perceptualRoughness);
			indirectSpec *= GBFresnelLerp(specularColor,GrazingTerm(smoothness,oneMinusReflectivity),NoV);
            indirectSpec *= _EnvSpecPower ;			

			//间接散射光处理
			float3 indirectDiff = (float3)1;
			GONBEST_APPLY_INDIRECT_DIFFUSE_COLOR(i,N,P,indirectDiff); 			
			indirectDiff *= _EnvDiffPower;
			indirectDiff *= diffColor;

			//散射计算
			float3 diff = NoL * diffColor * i.ml.w ;
			//高光计算
			float3 spec = GBBlinnPhongNDFTerm(NoH,rough) * specularColor * i.ml.w;			
			float3 pbrColor = (indirectSpec+indirectDiff) +  diff + spec;


			//各向异性的计算
			float4 mask = tex2D(_MainTex,i.uv.xy);	
			float shift = clamp(mask.r + mask.g * _SpecularShift - 0.2, -1, 1.33);
			float anisotropy = dot(shift * WN + B, V);
			anisotropy = 1- anisotropy*anisotropy;
			anisotropy = sqrt(anisotropy);
			anisotropy = sqrt(anisotropy);
			float3 aspec1 = pow(anisotropy,_SpecularPower1) * _SpecularColor1;
			float3 aspec2 = pow(anisotropy,_SpecularPower2) * _SpecularColor2 * mask.r;

			float3 aspec = (aspec1 + aspec2) * mask.b;
			float aspecRange = pow(dot(WN,V),_SpecularRange) ;
			aspec = saturate(aspec *  aspecRange);
			float3 abase = color.xyz;
			float3 aColor = aspec + abase;

			float4 Out = float4(lerp(aColor,pbrColor,_PBRInstensity),mask.a);		
			#if defined(_GONBEST_SPEC_ALPHA_ON)
				Out.a = 0;
			#endif	
			return Out;
		}			
	ENDCG	
	
	SubShader
	{	
		
		Pass
		{		
			//先写深度
			//这个Pass用处是写ZBuffer和Alpha信息,不写颜色信息
			//好处是,在pixelshader部分改变ZBuffer了,所以只能Late-Z,但是pixelshader的语句简单,所以能提高效率
		    Name "WRITE&Z&A"
			Tags  { "Queue" = "AlphaTest"  "RenderType" = "TransparentCutout" }
			Cull Off   
			ZWrite On			
			ZTest Less
			ColorMask 0   
            
			CGPROGRAM
			#pragma vertex vert_base
			#pragma fragment frag_write_z_a		
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON	
			ENDCG
		}	
		
		
		Pass
		{
			//这个跟着上面一个pass,这个因为在pixelshader部分,不改变ZBuffer,所以可以使用Early-Z进行优化.
			//关闭Z-Write，Z-Test模式为equal，剔除背面的三角形，再次绘制完全不透明的部分（仍然使用alpha-test模式，这次写color buffer）
			Name "WRITE&RGB&BASE"
			Tags { "LightMode" = "ForwardBase" "Queue" = "AlphaTest" "RenderType" = "TransparentCutout"} 
			
			Cull Off
			ZWrite Off
			ZTest Equal            
			
			CGPROGRAM
			
			#pragma vertex vert_base
			#pragma fragment frag_base					
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON							
			#pragma target 3.0
			ENDCG
		}

		Pass
		{
			//画半透明的部分
			Name "WRITE&BLEND&BACK"
			Tags { "LightMode" = "ForwardBase" "Queue" = "Transparent" "RenderType" = "Transparent"} 			
			
			Cull Front
			ZWrite Off
			ZTest Less
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
          		
			CGPROGRAM			
			#pragma vertex vert_base
			#pragma fragment frag_base					
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma target 3.0
			ENDCG
		}
		
		Pass
		{
			//画半透明的部分
			Name "WRITE&BLEND&FRONT"
			Tags { "LightMode" = "ForwardBase" "Queue" = "Transparent" "RenderType" = "Transparent"} 
			
			Cull Back
			ZWrite Off
			ZTest Less
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
            
			CGPROGRAM			
			#pragma vertex vert_base
			#pragma fragment frag_base						
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma target 3.0
			ENDCG
			
		}
	}		
}