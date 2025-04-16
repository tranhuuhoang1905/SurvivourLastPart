/*===============================================================
Author:gzg
Date:2020-01-02
Desc: 带有皮毛处理的PBR处理
===============================================================*/
Shader "Gonbest/PBR/FurPBRHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MainTex("Albedo", 2D) = "white" {}
		_BumpScale("Normal Map Scale",Range(0,2)) = 1  			//发现比率				
		_BumpMap("Normal Map",2D) = "black"{}		
		_Glossiness("Smoothness",Range(0,1)) = 0.2  //光滑度	
		_Metallic("Metallic",Range(0,1)) = 0  //光滑度
		_MetallicTex("Metallic(R)&Glossiness(G)&Skin(B)",2D) = "white"{}  	//金属度	
		_EnvDiffPower("Cube Diff Power",Range(0,4)) = 1
		_EnvSpecPower("Cube Spec Power",Range(0,4)) = 1
		_EnvCubeMipLevel("Cube MipLevel" , Range(0,100)) = 32
		_EnvCube("Cube Map", Cube) = "grey" {}	
		_DiffuseColor ("Diffuse Color", Color) = (0.7, 0.7, 0.7, 0.7)						
		_SpecPower("SpecPower",Range(0,10)) = 1			
		_OA("OA",Range(0,1)) = 0.5
		_MainLightPos("Main Light Pos",Vector) = (0,0,0,1)
		_MainLightColor("Main Light Color",Color) = (1,1,1,1)
		_FillInLightPos("Fill In Light Pos",Vector) = (0,0,0,0)
		_FillInLightColor("Fill In Light Color",Color) = (1,1,1,1)			
		_MaskTex("Flow(R)&Flash(G)&LogicColor(B) MaskTex",2D) = "black"{}  	//Mask贴图
		_FlowTex ("Flow (RGB)", 2D) = "black" {}		
		_FlowNoiseTex ("Flow Distort Noise Tex (RG)", 2D) = "black" {}
		_FlowType ("Flow Type:(T<1,T<2,T<3,T>3)", Float) = 0
		_FlowStrength("FlowStrength",Range(0,2)) = 1
		_FlowSpeed ("Flow Speed", Float) = 1.0
		_FlowTileCount("Flow Tile Count",Float) = 1
		_FlowColor ("Flow Color1", Color) = (1, 1, 1, 1)		
		_FlowColor2("Flow Color2", Color) = (1, 1, 1, 1)		
		_FlowForceX  ("Flow Strength X", range (0,1)) = 0.1
		_FlowForceY  ("Flow Strength Y", range (0,1)) = 0.1
		_FlashSpeed("FlashSpeed",Float) = 1
		_FlashColor("FlashColor", Color) = (1, 1, 1, 1)
		_LogicColor("LogicColor", Color) = (0, 0, 0, 0)
        _ISUI("(> 0.5) is ui",Float) = 0
        _FurNoiseTex ("_FurNoiseTex(皮毛的噪音图)", 2D) = "black" {}	
        _FurLength("_FurLength(皮毛的长度)",Float) = 0
        _FurThinness("_FurThinness(皮毛的粗细)",Float) = 1
        _FurDensity("_FurDensity(皮毛的密度)",Float) = 1        
        _ForceGlobal("_ForceGlobal(力的方向(世界))",Vector) = (0,0,0,0)
        _ForceLocal("_ForceLocal(力的方向(本地))",Vector) = (0,0,0,0)         
	}
	
	
	SubShader
	{ 
        Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "Queue" = "Transparent" }
		ZTest LEqual
	    Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
		ZWrite On	
        Cull Off
        Pass
		{//一个最基本的通用型Pass,透明

			Name "COMMON&BLEND"			
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base				
                #define FURSTEP 0.00
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC															
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	


        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&A"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.05
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&B"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.1
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&C"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.15
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	
        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&D"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.2
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	
        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&E"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.25
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&F"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.3
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&G"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.35
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	
		
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&H"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.4
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&I"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.45
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	
        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&J"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.5
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&K"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.55
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&L"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.6
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&M"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.65
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&N"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.7
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&O"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.75
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&P"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.8
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&Q"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.85
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&R"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.9
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&S"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 0.95
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	

        
        Pass
		{//一个最基本的通用型Pass,透明

			Name "FUR&T"
			CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base		
				#define FURSTEP 1.0
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
				#pragma multi_compile _GONBEST_ENV_MIP_LEVEL_METALIC	
                #pragma multi_compile _GONBEST_FUR_ON														
				#pragma multi_compile_fog	
				#pragma target 3.0
				#include "../Include/Program/FurProgram.cginc"
			ENDCG
		}	
	}
}