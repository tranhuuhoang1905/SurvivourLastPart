/*
Author:gzg
Date:2019-08-29
Desc:这个Shader,用于产生阴影,没有alpha处理
*/

Shader "Gonbest/FallBack/FBWithShadow"
{
	Properties
	{

	}

	SubShader
	{ 
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
		UsePass "Gonbest/Function/ShadowCasterHelper/SHADOWCASTER"	
	}

    Fallback "Gonbest/FallBack/FBNothing"
}