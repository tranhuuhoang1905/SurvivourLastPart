/*
Author:gzg
Date:2019-08-29
Desc:这个Shader,用于产生阴影,有alpha的处理
*/

Shader "Gonbest/FallBack/FBWithShadowAlpha"
{
	Properties
	{
        _MainTex ("Base (RGB)", 2D) = "white" {}	
		_Cutoff("Cutoff",float) = 0.1	
	}

	SubShader
	{ 
		Tags { "RenderType"="Opaque" }
		UsePass "Gonbest/Function/ShadowCasterHelper/SHADOWCASTER&ALPHATEST"	
	}

    Fallback "Gonbest/FallBack/FBWithShadow"
}