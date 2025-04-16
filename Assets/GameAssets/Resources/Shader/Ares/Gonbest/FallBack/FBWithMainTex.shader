/*===============================================================
Author:gzg
Date:2020-05-29
Desc:这个Shader是用于只用于显示一张图片
=================================================================*/
Shader "Gonbest/FallBack/FBWithMainTex"
{
	Properties
    {
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_ColorMultiplier("Color Multipler",Range(0,2)) = 1
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON

            #include "UnityCG.cginc"
			#include "../Include/Utility/WidgetUtilsCG.cginc"  

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;      
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);  
				GONBEST_APPLY_COLOR_MULTIPLIER(col);              
                return col;
            }
            ENDCG
        }
    }
}