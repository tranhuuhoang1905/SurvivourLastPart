// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

/*===============================================================
Author:gzg
Date:2019-12-03
Desc:这里处理当模型被挡住的渲染 --一般使用比较特殊
=================================================================*/
Shader "Gonbest/Function/ZTestGreaterHelper"
{
	Properties
	{
	}
    SubShader
    {
        Pass
		{//这个Pass主要是用来,当模型被挡住后来显示用的.
			Name "XRAY"
			ZTest Greater
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
            Lighting Off
            ZWrite Off
			Cull Back			
			CGPROGRAM
				#pragma vertex vert_xray
				#pragma fragment frag_xray
				#pragma fragmentoption ARB_precision_hint_fastest
				#include "UnityCG.cginc"
				#include "../Include/Base/MathCG.cginc"
			

				//为XRay增加的混合效果
				struct v2f_xray
				{
					float4 pos 		: POSITION;
					half2 uv 		: TEXCOORD0;
					half rim		: TEXCOORD1;
					UNITY_FOG_COORDS(2)
				};

				v2f_xray vert_xray( appdata_base v )
				{
					v2f_xray o = ( v2f_xray )0;
					o.pos = UnityObjectToClipPos( v.vertex );		
					o.uv = v.texcoord.xy;
					float3 wn = mul(float4(v.normal.xyz,0),unity_WorldToObject).xyz;
					float3 wp = mul(unity_ObjectToWorld,v.vertex).xyz;
					o.rim = dot(GBNormalizeSafe(wn), GBNormalizeSafe(_WorldSpaceCameraPos.xyz - wp)) ;
					UNITY_TRANSFER_FOG(o, o.pos);
					return o;
				}

				fixed4 frag_xray( v2f_xray i ) : COLOR
				{
					fixed4 color =(1-i.rim).x*float4(0.1,0.2,0.7,1);
					UNITY_APPLY_FOG(i.fogCoord, color);
					return color;
				}
			ENDCG
		}
    }
}