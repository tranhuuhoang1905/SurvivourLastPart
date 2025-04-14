//这个Shader是用来为了为其他Shader提供一些特殊的Pass
Shader "Gonbest/Legacy/BodyHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_ColorMultiplier("Color Multipler",Range(0,2)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MainTex ("Base (RGB)", 2D) = "white" {}				
		_MaskTex ("Mask (R = flow mask)", 2D) = "white" {}		
		_FlowTex ("Flow (RGB)", 2D) = "black" {}		
		_FlowNoiseTex ("Flow Distort Noise Tex (RG)", 2D) = "white" {}
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
		_MipmapLevel ("Mipmap Level", float) = 0.5		
		_EnvCube("_EnvCube", Cube) = "black"{}
		_EnvCubeMixer("_EnvCubeMixer",float) = 1
		_GrayFactor("GrayFactor",Range(0,1)) = 0
	}

	CGINCLUDE
		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Utility/WidgetUtilsCG.cginc"
        #include "../Include/Utility/FlowUtilsCG.cginc"
        #include "../Include/Utility/FogUtilsCG.cginc"

		uniform sampler2D _MainTex;	        			
		uniform half4 _MainTex_ST; 	
        uniform sampler2D _MaskTex;		
		

		struct v2f_base
		{
			float4 pos	: SV_POSITION;
			half4 uv	: TEXCOORD0;						
			GONBEST_FOG_COORDS(1)	
			GONBEST_MATCAP_COORDS(2)
            GONBEST_CUBE_COORDS(3)			
		};

		v2f_base vert_base(appdata_full v)
		{
			v2f_base o =(v2f_base)0;	
            float4 wpos = mul(unity_ObjectToWorld,v.vertex);
            float3 wnormal = mul(v.normal.xyz,(float3x3)unity_WorldToObject);
			o.pos = mul(UNITY_MATRIX_VP,wpos);
			o.uv.xy = TRANSFORM_TEX( v.texcoord, _MainTex );	
            o.uv.zw = GONBEST_CALC_FLOW_UV(v,  GONBEST_USE_FLOW_UV(v.texcoord,v.texcoord1));	
			GONBEST_TRANSFER_MATCAP(v,o);			
			//获取雾的采样点			
			GONBEST_TRANSFER_FOG(o, o.pos, wpos);	
            GONBEST_TRANSFER_CUBE(o, wnormal, wpos)
			return o;
		}

		fixed4 frag_base(v2f_base i) :COLOR
		{
			fixed4 color = GONBEST_TEX_SAMPLE(_MainTex,i.uv.xy);	
            fixed4 maskColor = tex2D(_MaskTex,i.uv.xy);	
			//颜色闪烁
			GONBEST_APPLY_FLASH(color, maskColor.g, i.uv.xy);				
            GONBEST_APPLY_FLOW(i.uv.zw,color,maskColor.r);					
			GONBEST_APPLY_COLOR_MULTIPLIER(color);
			//应用AlphaTest
			GONBEST_APPLY_ALPHATEST(color)
			GONBEST_APPLY_MATCAP(i,color)	
            GONBEST_CUBE_APPLY(i, color)
            GONBEST_APPLY_FOG(i, color);
			GONBEST_APPLY_GRAY(color)
			#if defined(_GONBEST_SPEC_ALPHA_ON)
				color.a = 0;
			#endif
			return color;
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
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base						
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON		
			ENDCG
		}		

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST"								
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base							
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
				
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&ALPHATEX"								
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base							
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ALPHA_TEX_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
				
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass
			Name "COMMON&BLEND"		
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off	
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				//#pragma multi_compile_fog			
			ENDCG
		}
		Pass
		{//一个最基本的通用型Pass
			Name "COMMON&BLEND&ALPHATEX"		
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off	
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				#pragma multi_compile _GONBEST_ALPHA_TEX_ON
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				//#pragma multi_compile_fog			
			ENDCG
		}	
 		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLOW"								
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base						
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF											
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
				
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLOW&ALPHATEX"								
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#pragma multi_compile _GONBEST_ALPHA_TEX_ON				
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF											
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
				
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&FLOW"								
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF									
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
			ENDCG
		}

		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLOW"						
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF															
				//#pragma multi_compile_fog				
			ENDCG
		}

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLUX"						
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base	
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON							
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLUX&ALPHATEX"						
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base	
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
				#pragma multi_compile _GONBEST_ALPHA_TEX_ON			
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON							
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&FLUX"							
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base	
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&FLUX&ALPHATEX"							
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base	
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ALPHA_TEX_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			ENDCG
		}	



		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLUX"						
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON										
				//#pragma multi_compile_fog					
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLUX&ALPHATEX"						
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ALPHA_TEX_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_FLUX_ON										
				//#pragma multi_compile_fog					
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&BLINK"							
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_BLINK_ON							
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&BLINK"			
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_BLINK_ON				
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
			ENDCG
		}	


		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&BLINK"						
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_BLINK_ON										
				//#pragma multi_compile_fog	
			ENDCG
		}

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&DISTORT"						
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base	
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_DISTORT							
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&DISTORT&ALPHATEX"						
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base	
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
				#pragma multi_compile _GONBEST_ALPHA_TEX_ON			
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_DISTORT							
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON			
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明使用镂空

			Name "COMMON&ALPHATEST&DISTORT"							
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base	
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_DISTORT				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			ENDCG
		}	


		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&DISTORT"						
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF				
                #pragma multi_compile _GONBEST_FLOW_DISTORT										
				//#pragma multi_compile_fog					
			ENDCG
		}
		
		Pass
		{//一个最基本的通用型Pass,非透明-使用Matcap图片
			Name "COMMON&MATCAP"					
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base						
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_MATCAP_ON
				#pragma multi_compile _GONBEST_MATCAP_MIX_ON
				//#pragma multi_compile_fog		
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明-使用Matcap图片
			Name "COMMON&CUBE"					
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base						
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_CUBE_ON				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON		
			ENDCG
		}		

		Pass
		{//一个最基本的通用型Pass,非透明-使用Matcap图片
			Name "COMMON&ALPHATEST&CUBE"					
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base						
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_CUBE_ON
				#pragma multi_compile _GONBEST_ALPHA_TEST_ON				
				//#pragma multi_compile_fog	
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON		
			ENDCG
		}		

		Pass
		{//一个最基本的通用型Pass,非透明-使用Matcap图片
			Name "COMMON&BLEND&CUBE"					
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off				
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base						
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
				#pragma multi_compile _GONBEST_ENV_CUBE_ON				
				//#pragma multi_compile_fog			
			ENDCG
		}

		Pass
		{//一个最基本的通用型Pass,非透明-使用Matcap图片
			Name "COMMON&BLEND&GRAY"					
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off				
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_GRAY_ON											
			ENDCG
		}	

		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON&FLASH"							
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#pragma multi_compile _GONBEST_FLASH_ON                				
				#pragma multi_compile _GONBEST_FLASH_TEX_ON
				#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			ENDCG
		}	
		
		/****************** DoubleFace ********************/
		Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND&FLOW&BACK"						
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha	
			Cull Front						
			ZWrite Off			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				//#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON								
				#pragma multi_compile _GONBEST_FLOW_ON _GONBEST_FLOW_OFF															
				//#pragma multi_compile_fog				
			ENDCG
		}
		
	}
}