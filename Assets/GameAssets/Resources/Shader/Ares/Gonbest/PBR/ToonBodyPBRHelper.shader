//这个Shader是用来为了为其他Shader提供一些特殊的Pass
Shader "Gonbest/PBR/ToonBodyPBRHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MainTex("Albedo", 2D) = "white" {}      
		_MaskTex ("MaskTex(R:光滑度，G：阴影效果，B：高光强度,A:自发光)", 2D) = "white" {}				
        _ShadowRange("ShadowRange(阴影范围)", Range(0 , 1)) = 0
		_ShadowPower("ShadowPower(阴影强度)", Range(0 , 1)) = 0.8
        _ShadowSmooth("ShadowSmooth(阴影边缘锐化程度)", Range(0 , 1)) = 0.8
		_ShadowContrast("ShadowContrast(阴影对比度)",Range(0,1)) = 0.5
        _SpecularRange ("SpecularRange(高光范围)", Range(0.5, 1)) = 0.998
        _SpecularPower ("SpecularPower(高光强度)", Range(0, 1)) = 0.88        
        _RimRampSmooth("RimRampSmooth(边缘光边缘锐化程度)",Range(0,1)) = 0
        _RimPower("RimPower(边缘光范围)",Range(0,2)) = 1
        _RimColor("RimColor(边缘光颜色)",Color) = (1,1,1,1) 	
		_EmissionColor ("EmissionColor(自发光颜色)", Color) = (0,0,0,0) 	
	}	
	
	SubShader
	{ 		
		Pass
		{//一个最基本的通用型Pass,非透明

			Name "COMMON"			
			Tags { "LightMode" = "ForwardBase" }
            ZTest LEqual
            Cull back
            ZWrite On			
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag	
                #define FURSTEP 0.00
                #pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON
				#pragma multi_compile_fog	
				#pragma target 3.0
                #include "../Include/Program/ToonFurProgram.cginc"
                
			ENDCG
		}
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P01"
            Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.05
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P02"
            Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.1
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON											
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P03"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.15
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON												
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	
        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P04"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.2
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	
        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P05"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.25
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P06"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.3
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P07"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.35
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON												
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	
		
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P08"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.4
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P09"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.45
			    #pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	
        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P10"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.5
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P11"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.55
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P12"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.6
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P13"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.65
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P14"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.7
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P15"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.75
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P16"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.8
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P17"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.85
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P18"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.9
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P19"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 0.95
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON												
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P20"
             Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		    ZTest LEqual
            ZWrite On
            Cull off
	        Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag		
				#define FURSTEP 1.0
				#pragma multi_compile _GONBEST_SHADOW_ON
                #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH 
                #pragma multi_compile _GONBEST_UNITY_SHADOW_ON
			    #pragma multi_compile SHADOWS_SCREEN
                //#pragma multi_compile _GONBSE_TOON_RIM_ON	
                #pragma multi_compile _GONBEST_FUR_ON	
                #pragma multi_compile _GONBEST_FUR_FORCE_ON
                #pragma multi_compile _GONBEST_FUR_SHADE_ON													
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/ToonFurProgram.cginc"
			ENDCG
		}		
	}

    Fallback "Gonbest/FallBack/FBWithShadow"
}