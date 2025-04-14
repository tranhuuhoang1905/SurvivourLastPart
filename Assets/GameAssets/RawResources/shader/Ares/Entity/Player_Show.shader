Shader "Ares/Entity/Player_Show"
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
		_MetallicTex("Metallic(R)&Glossiness(G)&Skin(B) Tex",2D) = "white"{}  	//金属度	
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
		_LogicColor("LogicColor", Color) = (1, 1, 1, 1)	
		_SSSColor("SSSColor",Color) = (0,0,0,0)		
		_ISUI("(> 0.5) is ui",float) = 0
		_BloomTex ("BloomTex", 2D) = "(0.5,0.5,0.5,0.5)" {}
		_BloomFactor("BloomFactor", float) = 0
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue" = "Geometry-50" "GonbestBloomType"="BloomMask"}		
		LOD 250
        UsePass "Gonbest/PBR/BodyPBRHelper/COMMON"
	}	
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue" = "Geometry-50" "GonbestBloomType"="BloomMask"}	
        UsePass "Gonbest/Legacy/BodyHelper/COMMON"
	}	
	Fallback "Gonbest/FallBack/FBNothing"
}
