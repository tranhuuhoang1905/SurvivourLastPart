Shader "Gonbest/Function/CustomShadowCasterHelper"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

    CGINCLUDE        
        #include "../Include/Base/CommonCG.cginc"
        uniform sampler2D _MainTex;
		uniform half4 _MainTex_ST;	
        struct vertexdata
        {
            float4 vertex : POSITION;
            half4 texcoord : TEXCOORD0;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv: TEXCOORD0;
        };	
        v2f vert(vertexdata v)
        {
            v2f o = (v2f)0;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv =TRANSFORM_TEX(v.texcoord, _MainTex);            
            return o;
        }
        //只有深度信息
        float4 fragonlydepth(v2f i) : COLOR
        {
            float d = i.pos.z/i.pos.w;
            if(UNITY_NEAR_CLIP_VALUE < 0)//https://docs.unity3d.com/Manual/SL-PlatformDifferences.html
            {//UNITY_NEAR_CLIP_VALUE:这个值为负,因为使用的正交视图.
                //因为GL的区间再[-1,1]之间,所以转换到[0,1]
                d = d / 2 + 0.5;//GL需要将深度值转到[0,1]
            }
			return float4(d,0,0,0);  
        }
        //只会读取图片的alpha值
        float4 fragonlyalpha(v2f i) : COLOR
        {
            float4 c = tex2D(_MainTex,i.uv.xy);
            return GBEncodeFloatRGBA(c.a * 0.5); 
        }

        //只会读取图片的red值
        float4 fragonlyred(v2f i) : COLOR
        {
            float4 c = tex2D(_MainTex,i.uv.xy);
            return GBEncodeFloatRGBA(c.r * 0.5); 
        }

    ENDCG

	SubShader
	{
		
        Pass
		{
            //这个是通过深度来生成阴影纹理
            Name "COMMON&DEPTH" 
            Tags { "RenderType" = "Opaque" }
			Blend One Zero 
			ZTest LEqual
			ZWrite On			
			Lighting Off
			Fog {Mode Off}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment fragonlydepth
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"			
			ENDCG
		}

		Pass
		{
            //这个时通过纹理的alpha来生成阴影纹理
            Name "COMMON&ALPHA" 
            Tags { "RenderType" = "Opaque" }
			Blend One Zero 
			ZTest LEqual
			ZWrite On			
			Lighting Off
			Fog {Mode Off}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment fragonlyalpha
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"			
			ENDCG
		}

      

        Pass
		{
           //这个时通过纹理的red来生成阴影纹理
            Name "COMMON&RED" 
            Tags { "RenderType" = "ShadowMesh"}

			Blend One Zero 
			ZTest LEqual
			ZWrite On
			Cull Off
			Lighting Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragonlyred
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG
		}
	}
	
}