// Upgrade NOTE: replaced 'mul(GONBEST_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//风的Pass提供者
Shader "Gonbest/Legacy/WindHelper"
{
	Properties
	{		
        _Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex("Base (RGB)", 2D) = "white" {}				
        _DiffuseColor("EmissiveColor",Color) = (0.7,0.7,0.7,0)
	}
	
	CGINCLUDE
        #include "../Include/Base/CommonCG.cginc"
        #include "../Include/Utility/FogUtilsCG.cginc"
        #include "../Include/Utility/FlowUtilsCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
        #include "../Include/Utility/WindUtilsCG.cginc"
        #include "../Include/Indirect/Lightmap&SHLightCG.cginc"

		uniform sampler2D _MainTex;	
		uniform half4 _MainTex_ST;	
		
		struct v2flit
		{
			float4 pos 			: POSITION;			
			half4 uv 			: TEXCOORD0;
			half2 litmapuv 		: TEXCOORD1;					
			float3 wn			: TEXCOORD2;  
			float4 wpos			: TEXCOORD3;	          			
			GONBEST_FOG_COORDS(4)			
			GONBEST_SHADOW_COORDS(5)
			UNITY_VERTEX_INPUT_INSTANCE_ID	
		};		
		//顶点处理程序
		v2flit vert_lit (appdata_full v)
		{
			UNITY_SETUP_INSTANCE_ID(v);
			v2flit o = (v2flit)0;
            //顶点处理
			GONBEST_TRANSFER_WIND(v)
			o.pos = UnityObjectToClipPos(v.vertex);
            float4 wpos = mul(unity_ObjectToWorld,v.vertex);

            //UV处理
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);			
			GONBEST_TRANSFER_SCROLL_UV(v,o)

			//Lightmap的处理
			o.litmapuv.xy = GONBEST_CALC_LIGHTMAP_UV(v.texcoord1);

			//法线
			o.wn = UnityObjectToWorldNormal(v.normal);			
            
			//阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);			
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.pos, wpos.xyz);	
			UNITY_TRANSFER_INSTANCE_ID(v, o);	
			return o;
		}

		fixed4 frag_lit(v2flit i) : COLOR
		{
			UNITY_SETUP_INSTANCE_ID(i);
			fixed4 tex = GONBEST_TEX_SAMPLE(_MainTex, i.uv.xy);
			GONBEST_APPLY_ALPHATEST(tex);
			GONBEST_APPLY_SCROLL_UV(i,tex);
			GONBEST_APPLY_COLOR_MULTIPLIER(tex);

			fixed4 Albedo = tex;	
			//处理散射灯光
			tex.rgb = _LightColor0.rgb * max (0, dot(i.wn, _WorldSpaceLightPos0.xyz));
			//应用lightmap
			tex.rgb += Albedo;

            float3 idiff = (float3)1;
            GONBEST_APPLY_LIGHTMAP_COLOR(i.litmapuv.xy,idiff);
			//阴影处理 						
			idiff *= GONBEST_DECODE_SHADOW_VALUE(i,i.wpos);

            tex.rgb *= idiff;
			//对应模型雾的颜色
			GONBEST_APPLY_FOG(i, tex);	
			#if defined(_GONBEST_SPEC_ALPHA_ON)
				tex.a = 0;
			#endif
			return tex;
		}		

		struct v2f
		{
			float4 pos 		: POSITION;			
			half4 uv 			: TEXCOORD0;	
			GONBEST_FOG_COORDS(1)
			UNITY_VERTEX_INPUT_INSTANCE_ID	
			
		};		
		//顶点处理程序
		v2f vert (appdata_full v)
		{
			UNITY_SETUP_INSTANCE_ID(v);
			v2f o = (v2f)0;
			GONBEST_TRANSFER_WIND(v)
			o.pos = UnityObjectToClipPos(v.vertex);
            float4 wpos = mul(unity_ObjectToWorld,v.vertex);

			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);			
			GONBEST_TRANSFER_SCROLL_UV(v,o)
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.pos, wpos.xyz);
			UNITY_TRANSFER_INSTANCE_ID(v, o);	
			return o;
		}

		fixed4 frag(v2f i) : COLOR
		{
			UNITY_SETUP_INSTANCE_ID(i);
			fixed4 tex = GONBEST_TEX_SAMPLE(_MainTex, i.uv.xy);
			GONBEST_APPLY_ALPHATEST(tex);
			GONBEST_APPLY_SCROLL_UV(i,tex);
			GONBEST_APPLY_COLOR_MULTIPLIER(tex);
			//对应模型雾的颜色
			GONBEST_APPLY_FOG(i, tex);
			#if defined(_GONBEST_SPEC_ALPHA_ON)
				tex.a = 0;
			#endif
			return tex;
		}		
	ENDCG

	SubShader
	{	
		Lighting Off
		Cull Off
		ZWrite Off	
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "WIND&ADD"		
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON
			#pragma multi_compile_fog				
			#pragma multi_compile_instancing
			ENDCG
		}		
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "WIND&ADD&ALPHATEX"		
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON	
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile_fog				
			#pragma multi_compile_instancing
			ENDCG
		}		
		
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "WIND&BLEND"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON	
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing			
			ENDCG
		}		
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "WIND&BLEND&ALPHATEX"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing		
			ENDCG
		}
		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "WIND&SCROLL&ADD"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			ENDCG
		}		
		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "WIND&SCROLL&ADD&ALPHATEX"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			ENDCG
		}		
		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "WIND&SCROLL&BLEND"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "WIND&SCROLL&BLEND&ALPHATEX"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
		
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COMPLEX_WIND_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{   
			Name "WINDGRASS"
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_SIMPLE_WIND_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			ENDCG
		} 		
		Pass
		{   
			Name "WINDGRASS&ALPHATEX"
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON			
			#pragma multi_compile _GONBEST_SIMPLE_WIND_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON
			ENDCG
		}
		Pass
		{   
			Name "WINDGRASS&LIT"	
			Tags { "LightMode" = "ForwardBase" }		
			ZWrite On
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_SIMPLE_WIND_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing	
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON		
			ENDCG
		} 		 
	}
}