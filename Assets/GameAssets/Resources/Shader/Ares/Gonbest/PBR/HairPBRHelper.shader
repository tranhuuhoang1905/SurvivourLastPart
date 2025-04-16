/*===============================================================
Author:gzg
Date:2020-01-02
Desc: 头发的渲染处理
===============================================================*/
Shader "Gonbest/PBR/HairPBRHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
		_MainTex("Base (RGB)", 2D) = "white" {}
		_MaskTex ("Mask", 2D) = "white" {}	
		_BumpScale("Normal Map Scale",Range(0,2)) = 1  			//发现比率				
		_BumpMap("Normal Map",2D) = "black"{}							
		_SpecularPower1("Specular Power 1",Range(0,100)) = 1			
		_SpecularColor1("Specular Color 1", Color) = (0.5,0.5,0.5,1)
		_SpecularShift1 ("Specular Shift 1 ", Range(-1.0, 1.0)) = 1		
		_SpecularPower2 ("Specular Power 2", Range(0, 100)) = 10		
		_SpecularColor2("Specular Color 2", Color) = (0.5,0.5,0.5,1)
		_SpecularShift2 ("Specular Shift 2 ", Range(-1.0, 1.0)) = 1		
		_MainLightPos("Main Light Pos",Vector) = (0,0,0,1)
		_MainLightColor("Main Light Color",Color) = (1,1,1,1)	
		_OA("OA",Range(0,1)) = 0.5	
		_ISUI("(> 0.5) is ui",float) = 0
	}
	CGINCLUDE

		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Specular/KajiyaKayCG.cginc"
		#include "../Include/Utility/WidgetUtilsCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/PixelUtilsCG.cginc"
		
		
		uniform sampler2D _MainTex;				
		uniform half4 _MainTex_ST;
		uniform sampler2D _MaskTex;
		uniform sampler2D _BumpMap;	
		uniform half _Cutoff;				
		uniform half _BumpScale;		
		uniform half _SpecularPower1;	
		uniform fixed3 _SpecularColor1;
		uniform fixed _SpecularShift1;
		uniform half _SpecularPower2;			
		uniform fixed3 _SpecularColor2;
		uniform fixed _SpecularShift2;
		uniform float4 _MainLightPos;
		uniform float3 _MainLightColor;	
		uniform float _OA;
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
			clip(color.a * color.a - _Cutoff);
			return color;
		}
		
		//基础处理
		fixed4 frag_base(v2f_base i): COLOR
		{			
			fixed4 color = tex2D(_MainTex,i.uv) ;
			
			GONBEST_APPLY_COLOR_MULTIPLIER(color);					

			float4 mask = tex2D(_MaskTex,i.uv);			
			
			float4 NT = tex2D(_BumpMap,i.uv.xy);

			float3 TN = GBUnpackScaleNormal(NT,_BumpScale);
			float3 T = GBNormalizeSafe(i.wt.xyz);
			float3 B = GBNormalizeSafe(i.wb.xyz);
			float3 WN = GBNormalizeSafe(i.wn.xyz);

			float3 N = GetWorldNormalFromBump(NT,_BumpScale,T,B,WN);			
			float3 P = float3(i.wt.w, i.wb.w, i.wn.w);
			float3 L = GBNormalizeSafe(i.ml.xyz);			
			float3 V = GetWorldViewDirWithUI(P, _ISUI);
			float3 H = GBNormalizeSafe(L+V);				

			float NoL = saturate(dot(N,L));						
			
			fixed2 specularHighlight = GBKajiyaKaySpecularTerm(N, B, H, _SpecularShift1 + mask.x, _SpecularShift2 + mask.y, _SpecularPower1, _SpecularPower2);
			
			fixed3 specular = ((specularHighlight.x * _SpecularColor1) + (specularHighlight.y *  _SpecularColor2)) * NoL;					
			
			fixed3 diffuse = _MainLightColor.rgb * NoL * i.ml.w;
			
			color.rgb += (specular + diffuse);
			
			GONBEST_PROCESS_ALPHA_OF_COLOR(color,color.a)
			
			return color;
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
			#pragma multi_compile_fwdbase			
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
			#pragma multi_compile_fwdbase			
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
			#pragma multi_compile_fwdbase			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma target 3.0
			ENDCG
			
		}
		
	}		
}