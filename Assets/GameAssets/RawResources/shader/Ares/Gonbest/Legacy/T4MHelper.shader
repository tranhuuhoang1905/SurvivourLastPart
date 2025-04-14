// Upgrade NOTE: replaced 'mul(GONBEST_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//运行时T4M的Shader处理
Shader "Gonbest/Legacy/T4MHelper"
{
	Properties
	{		
	}
	
	CGINCLUDE

		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
        #include "../Include/Indirect/Lightmap&SHLightCG.cginc"
        #include "../Include/Utility/T4MUtilsCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
        #include "../Include/Utility/FogUtilsCG.cginc"
		uniform sampler2D _Control;
		
		struct v2f
		{
			float4 vertex 		: POSITION;			
			half4 uv			: TEXCOORD0;	
			float4 wpos			: TEXCOORD1;			
			GONBEST_T4M_2_COORD(2)
			GONBEST_T4M_3_COORD(3)
			GONBEST_T4M_4_COORD(4)									
			GONBEST_SHADOW_COORDS(5)	
			GONBEST_FOG_COORDS(6)
			
		};		
		//顶点处理程序
		v2f vert (appdata_full v)
		{
			v2f o = (v2f)0;
            float4 wpos = mul(unity_ObjectToWorld,v.vertex);
			o.vertex = UnityObjectToClipPos( v.vertex );		
			o.uv.xy = v.texcoord;
            o.uv.zw = GONBEST_CALC_LIGHTMAP_UV(v.texcoord1.xy);		
			o.wpos = wpos;
			GONBEST_TRANSFER_T4M_2(v,o)
			GONBEST_TRANSFER_T4M_3(v,o)
			GONBEST_TRANSFER_T4M_4(v,o)			
			//阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.vertex,wpos);
					
			return o;
		}

		fixed4 frag(v2f i) : COLOR
		{
			fixed4 splat_control = tex2D( _Control, i.uv.xy );
			fixed4 mainTex = fixed4(0,0,0,0);
			GONBEST_APPLY_T4M_2(i,splat_control,mainTex);
			GONBEST_APPLY_T4M_3(i,splat_control,mainTex);
			GONBEST_APPLY_T4M_4(i,splat_control,mainTex);

			float3 indirectDiff = (float3)1;			
			GONBEST_APPLY_LIGHTMAP_COLOR(i.uv.zw,indirectDiff);

			//阴影处理
 			//float3 luminance = gonbest_ColorSpaceLuminance.rgb * indirectDiff.rgb ;
            //float backShadowValue = step(0.8, luminance.r + luminance.g + luminance.b);
			//indirectDiff = lerp(float3(0,0,0.5),indirectDiff,backShadowValue) * shadowValue ;			
			indirectDiff *= GONBEST_DECODE_SHADOW_VALUE(i,i.wpos);		

            mainTex.rgb *= indirectDiff;
			//对应模型雾的颜色
			GONBEST_APPLY_FOG(i, mainTex.xyz);
			mainTex.a = 0;
			return mainTex;
		}		
	ENDCG

	SubShader
	{	
		Lighting Off
		ZWrite On
		Pass
		{	//两张纹理
			Name "TWO"					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_OFF _GONBEST_SHADOW_ON
			#pragma multi_compile _GONBEST_T4M_2_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile_fog
			ENDCG
		}		
		Pass
		{	//三张纹理
			Name "THREE"					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_OFF _GONBEST_SHADOW_ON
			#pragma multi_compile _GONBEST_T4M_3_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile_fog
			ENDCG
		}		
		Pass
		{	//四张纹理
			Name "FOUR"					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_SHADOW_OFF _GONBEST_SHADOW_ON
			#pragma multi_compile _GONBEST_T4M_4_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile_fog
			ENDCG
		}		
			
	}
}