Shader "Ares/AAAAAAAAAAATest"
{
	Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex ("RG:各项异性光偏移&B:环境遮挡&A:透明度", 2D) = "white" {}	
		_Cutoff ("CutOff", Range(0,1)) = 0.3
		_SpecularShift("各项异性光偏移参数", Range( -1 , 1)) = -1
		_SpecularPower1("各项异性光强度1",Range(0,1000)) = 300			
		_SpecularColor1("各项异性光颜色1", Color) = (0.5,0.5,0.5,1)		
		_SpecularPower2 ("各项异性光强度2", Range(0, 100)) = 40		
		_SpecularColor2("各项异性光颜色2", Color) = (0.5,0.5,0.5,1)
		_SpecularRange("各项异性光范围", Range( 0 , 5)) = 0	

		_PBRInstensity("PBR的强度", Range( 0 , 1)) = 0
		_EnvDiffPower("间接散射光",Range(0,4)) = 1
		_EnvSpecPower("间接高光",Range(0,4)) = 1
		_EnvCube("环境Cube", Cube) = "grey" {}	
		_BumpScale("法线比率",Range(0,2)) = 1  			//发现比率				
		_BumpMap("法线贴图",2D) = "black"{}				
		_MainLightPos("主光方向",Vector) = (0,0,0,1)
		_MainLightColor("主光颜色",Color) = (1,1,1,1)
		
		_ISUI("(> 0.5) is ui",float) = 0
        
    }

	SubShader
	{
		UsePass "Gonbest/PBR/NewHairPBRHelper/WRITE&TEST"                
		UsePass "Gonbest/PBR/NewHairPBRHelper/WRITE&BLEND"

	}	
	
	Fallback "Gonbest/FallBack/FBNothing"
}
