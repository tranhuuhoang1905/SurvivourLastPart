//提供头发的卡通效果
Shader "Gonbest/PBR/ToonHairPBRHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
		_MainTex("Base (RGB)", 2D) = "white" {}
		_MaskTex ("Mask(R:高亮1的偏移，B：高亮2的偏移)", 2D) = "white" {}								
		_LightTex ("LightTex(R:自发光颜色,G：阴影)", 2D) = "white" {}	
		_SpecularPower1("Spe Power 1(高光1强度)",Range(0,100)) = 1			
		_SpecularColor1("Spe Color 1(高光1颜色)", Color) = (0.5,0.5,0.5,1)
		_SpecularShift1 ("Spe Shift 1(高光1偏移)", Range(-1.0, 1.0)) = 1		
		_SpecularPower2 ("Spe Power 2(高光2强度)", Range(0, 100)) = 10		
		_SpecularColor2("Spe Color 2(高光2颜色)", Color) = (0.5,0.5,0.5,1)
		_SpecularShift2 ("Spe Shift 2 (高光2偏移)", Range(-1.0, 1.0)) = 1					
		_ShadowRange("ShadowRange(阴影范围)",Range(0,1)) = 1
		_ShadowStrength("ShadowStrength(阴影强度)",Range(0,1)) = 1
        _ShadowSmooth("ShadowSmooth(阴影锐化)",Range(0,1)) = 0     
		_RimRampSmooth("RimRampSmooth(边缘光锐化)",Range(0,1)) = 0
        _RimPower("RimPower(边缘光强度)",Range(0,2)) = 1
        _RimColor("RimColor(颜色强度)",Color) = (1,1,1,1) 
		_EmissionColor ("EmissionColor(自发光颜色)", Color) = (0,0,0,0)       
		_ISUI("(> 0.5) is ui",float) = 0
	}
	CGINCLUDE


		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Specular/KajiyaKayCG.cginc"
		#include "../Include/Utility/WidgetUtilsCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/PixelUtilsCG.cginc"		
		#include "../Include/Utility/ToonUtilsCG.cginc"
		#include "../Include/Base/RampCG.cginc"		
        #include "../Include/Indirect/RimLightCG.cginc"
		
		
		uniform sampler2D _MainTex;				
		uniform half4 _MainTex_ST;
		uniform sampler2D _MaskTex;
		uniform half4 _MaskTex_ST;	
		uniform sampler2D _LightTex;	
		uniform half _Cutoff;				
		uniform half _BumpScale;		
		uniform half _SpecularPower1;	
		uniform fixed3 _SpecularColor1;
		uniform fixed _SpecularShift1;
		uniform half _SpecularPower2;			
		uniform fixed3 _SpecularColor2;
		uniform fixed _SpecularShift2;				
		uniform float _ISUI;
		uniform float _ShadowRange;
		uniform float _ShadowStrength;
		uniform float _ShadowSmooth;
		uniform float _RimPower;
        uniform float4 _RimColor;   
        uniform float4 _EmissionColor;          
        uniform float _RimRampSmooth = 0;  
			
		
		struct v2f_base
		{
			float4 pos	: SV_POSITION;
			half4 uv	: TEXCOORD0;
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;	
			float4 wl          : TEXCOORD4;		
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
			o.uv.zw = TRANSFORM_TEX( v.texcoord, _MaskTex );				
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

			float4 mask = tex2D(_MaskTex,i.uv.zw);

			//
			float3 ao = tex2D(_LightTex,i.uv.xy).rgb;
			ao.g *=2;

			float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
			float3 T = GBNormalizeSafe(i.wt.xyz);
			float3 B = GBNormalizeSafe(i.wb.xyz);
			float3 WN = GBNormalizeSafe(i.wn.xyz);
			float3 N = WN;					
			float3 P = float3(i.wt.w, i.wb.w, i.wn.w);
			float3 V = GetWorldViewDirWithUI(P, _ISUI);									
			float NoV = saturate(dot(N,V));			
            

			

			//diff		
			float NoL = saturate(dot(N,L)* 0.5 + 0.7) ;
			NoL = lerp(NoL,0,_ShadowRange);
			NoL = RampTwoStep(NoL,0.2,_ShadowSmooth * 0.1);
			float3 shadowColor = color.rgb * (1-_ShadowStrength);	
			float3 diff = lerp(shadowColor,color.rgb,NoL) * ao.g;			
			
			//spec
			float2 specularHighlight = GBKajiyaKaySpecularTerm(WN, B, V, _SpecularShift1 + mask.r , _SpecularShift2 + mask.b , _SpecularPower1 , _SpecularPower2);			
			float3 spec = specularHighlight.x * _SpecularColor1  + specularHighlight.y *  _SpecularColor2;		
 			spec *= GBPow4(NoV);
			spec *= NoL * ao.g;

			//rim
            float3 RimNoL = saturate(dot(N,GBNormalizeSafe(-L)));                                                    
            float rt = GBRimTerm(NoV, RimNoL,_RimPower);
            rt = RampTwoStep(rt,0.5,_RimRampSmooth*0.5);
            float3 rim = rt * _RimColor.rgb * _RimColor.a;

			 //emissive
            float3 emissive = color.rgb * ao.r * _EmissionColor.rgb;

			//输出颜色
			float4 outColor = color;
			outColor.rgb = diff;			
			outColor.rgb += rim;
			outColor.rgb += spec;								
			outColor.rgb += emissive;		
			
			return outColor;
		}			
	ENDCG	
	
	SubShader
	{	
	  
	  	Pass
		{
			//正常渲染一个模型
			Name "COMMON"
			Tags { "LightMode" = "ForwardBase"} 			
			Cull Off						
			CGPROGRAM			
			#pragma vertex vert_base
			#pragma fragment frag_base
			#pragma multi_compile_fwdbase			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON		
			#pragma multi_compile _GONBSE_TOON_DIFFUSE_ON					
			#pragma target 3.0
			ENDCG
		}

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
			#pragma multi_compile _GONBSE_TOON_DIFFUSE_ON
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
			ZWrite On
			ZTest Equal            
			
			CGPROGRAM
			
			#pragma vertex vert_base
			#pragma fragment frag_base
			#pragma multi_compile_fwdbase			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON		
			#pragma multi_compile _GONBSE_TOON_DIFFUSE_ON					
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
			#pragma multi_compile _GONBSE_TOON_DIFFUSE_ON					
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
			#pragma multi_compile _GONBSE_TOON_DIFFUSE_ON				
			#pragma target 3.0
			ENDCG
			
		}
		
	}		
}