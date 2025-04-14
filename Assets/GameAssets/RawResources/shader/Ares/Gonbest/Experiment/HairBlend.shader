Shader "Ares/AAAAAAAAAAABlend"
{
	Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex ("R:", 2D) = "white" {}		
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
		_AnisotropyBias("Anisotropy-Bias", Range( -1 , 1)) = -1
		_SpecularPower1("Specular Power 1",Range(0,1000)) = 300			
		_SpecularColor1("Specular Color 1", Color) = (0.5,0.5,0.5,1)		
		_SpecularPower2 ("Specular Power 2", Range(0, 100)) = 40		
		_SpecularColor2("Specular Color 2", Color) = (0.5,0.5,0.5,1)
		_HLFrePower("HL-Fre-Power", Range( 0 , 5)) = 0	
		_EnvDiffPower("Cube Diff Power",Range(0,4)) = 1
		_EnvSpecPower("Cube Spec Power",Range(0,4)) = 1
		_EnvCube("Cube Map", Cube) = "grey" {}	
		_BumpScale("Normal Map Scale",Range(0,2)) = 1  			//发现比率				
		_BumpMap("Normal Map",2D) = "black"{}				
		_MainLightPos("Main Light Pos",Vector) = (0,0,0,1)
		_MainLightColor("Main Light Color",Color) = (1,1,1,1)
		_PBRInstensity("PBR-Instensity", Range( 0 , 1)) = 0
		_OA("OA",Range(0,1)) = 0.5	
		_ISUI("(> 0.5) is ui",float) = 0
        
    }

	SubShader
	{
		//UsePass "Gonbest/PBR/NewHairPBRHelper/WRITE&TEST"                
		UsePass "Gonbest/PBR/NewHairPBRHelper/WRITE&BLEND"

	}	
	
	Fallback "Gonbest/FallBack/FBNothing"
}
