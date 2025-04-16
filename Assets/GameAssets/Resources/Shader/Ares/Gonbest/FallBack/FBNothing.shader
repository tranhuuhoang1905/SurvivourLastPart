/*
Author:gzg
Date:2019-08-29
Desc:这个Shader不做任何操作,输出为空
*/

Shader "Gonbest/FallBack/FBNothing"
{
	Properties
	{		
	}

	SubShader
	{ 
		Tags { "RenderType"="Opaque" }
		Pass
		{
			ColorMask 0
			ZWrite Off
		}
	}
}