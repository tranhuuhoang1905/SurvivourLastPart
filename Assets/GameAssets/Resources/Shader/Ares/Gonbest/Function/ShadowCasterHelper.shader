/*
Author:gzg
Date:2019-08-23
Desc:这里定义Unity生成阴影图的Shader.
*/
Shader "Gonbest/Function/ShadowCasterHelper"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}	
        _Cutoff("Cutoff",float) = 0
	}

    CGINCLUDE        
        #include "../Include/Shadow/ShadowCG.cginc"

        uniform sampler2D _MainTex;				
		uniform float4 _MainTex_ST;
        uniform float _Cutoff;

        struct appdata
        {
            float4 vertex : POSITION;	
            float3 normal :NORMAL;			
            float2 texcoord:TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv :TEXCOORD0;
            float3 vec : TEXCOORD1;
        };

        v2f vert (appdata v)
        {
            v2f o = (v2f)0;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;				
            GONBEST_TRANSFER_SHADOW_CASTER_NOPOS(o,o.vertex)	
            return o;			
        }

        half4 frag(v2f i) : SV_Target
        {
            GONBEST_SHADOW_CASTER_FRAGMENT(i)
        }

        half4 frag_alpha(v2f i) : SV_Target
        {
            float4 color = tex2D(_MainTex,i.uv);
            clip(color.a - 0.1);
            GONBEST_SHADOW_CASTER_FRAGMENT(i)
        }
    ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {//阴影的产生者
            Name "SHADOWCASTER"
            Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag   
            #pragma multi_compile _GONBEST_SHADOW_ON
            #pragma multi_compile _GONBEST_UNITY_SHADOW_ON              
            #pragma multi_compile_shadowcaster          
            ENDCG
        }

        Pass
        {//阴影的产生者
            Name "SHADOWCASTER&ALPHATEST"
            Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_alpha  
            #pragma multi_compile _GONBEST_SHADOW_ON
            #pragma multi_compile _GONBEST_UNITY_SHADOW_ON               
            #pragma multi_compile_shadowcaster          
            ENDCG
        }
	}
}