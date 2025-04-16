//UV滚动的Pass提供者
Shader "Gonbest/Legacy/ScrollUVHelper"
{
	Properties
	{		
        _Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex("Base (RGB)", 2D) = "white" {}				
        _AlphaTex("_AlphaTex", 2D) = "white" {}	
        _AlphaTex2("_AlphaTex2", 2D) = "white" {}	
		_UseClip("UseClip",float) = 0
		_ClipRect("ClipRect",Vector)= (-50000,-50000,50000,50000)
		_InsideColor("内部颜色",Color) = (1, 1, 0, 1)
        _ClipMaxLength("被切的最大长度",float) = 4
        _ClipAmount("切的进度信息",Range(-1 , 1)) = 0
        _EdgeWidth("切割部位的高度",Range(0 , 1)) = 0.2
        _EdgeColor("切割部位的颜色",Color) = (1, 1, 0, 1)   
	}
	
	CGINCLUDE
		#include "../Include/Base/CommonCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"
        #include "../Include/Utility/FlowUtilsCG.cginc"
		
		uniform sampler2D _MainTex;		
		uniform half4 _MainTex_ST;		
		
		struct appdata_t
		{
			float4 vertex	: POSITION;
			fixed4 color	: COLOR;
			half2 texcoord 	: TEXCOORD0;
			UNITY_VERTEX_INPUT_INSTANCE_ID					
		};

		struct v2f
		{
			float4 vertex 		: POSITION;
			fixed4 color 		: COLOR;
			half4 uv 			: TEXCOORD0;
			float3 wpos         : TEXCOORD1;
			GONBEST_MODEL_CLIP_COORDS(2)
			UNITY_VERTEX_INPUT_INSTANCE_ID	
			
		};

		v2f vert(appdata_t v)
		{
			UNITY_SETUP_INSTANCE_ID(v);
			v2f o = (v2f)0;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.color = v.color;
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.wpos = mul(unity_ObjectToWorld,v.vertex).xyz;
			GONBEST_TRANSFER_MODEL_CLIP_Y(v,o);
			GONBEST_TRANSFER_SCROLL_UV(v,o)	
			UNITY_TRANSFER_INSTANCE_ID(v, o);	
			return o;
		}

		fixed4 frag(v2f i,float facing:VFACE) : COLOR
		{
			UNITY_SETUP_INSTANCE_ID(i);
			fixed4 tex = GONBEST_TEX_SAMPLE(_MainTex, i.uv.xy) ;
			GONBEST_APPLY_SCROLL_UV(i,tex);
			GONBEST_APPLY_COLOR_MULTIPLIER(tex)
			float a = GONBEST_APPLY_IN_CLID_RECT(i.wpos);
			tex *= i.color;
			tex.a *= a;
			fixed4 finalColor = (fixed4)0;
			GONBEST_MODEL_CLIP_APPLY(i,facing,tex,1,finalColor);
			return finalColor;
		}
	ENDCG

	SubShader
	{
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "ONE&ADD"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "TWO&ADD"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_TWO_SCROLL_UV_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}	
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "ONE&BLEND"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			#pragma multi_compile_instancing	
			ENDCG
		}		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "TWO&BLEND"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_TWO_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			#pragma multi_compile_instancing	
			ENDCG
		}

		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "ONE&ADD&ALPHATEX"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "TWO&ADD&ALPHATEX"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_TWO_SCROLL_UV_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_TWO_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}	
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "ONE&BLEND&ALPHATEX"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}		
		Pass
		{	//两张滚动Shader的通用的顶点片段程序
			Name "TWO&BLEND&ALPHATEX"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			Cull Off 
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_TWO_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_TWO_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}	
		Pass
		{	//一张滚动Shader的通用的顶点片段程序
			Name "ONE&BLEND&MODELCLIP"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			Cull Off 			
			ZWrite Off			
            AlphaToMask on
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON		
			#pragma multi_compile _GONBEST_MODEL_CLIP_ON
			#pragma multi_compile_instancing
			ENDCG
		}				
	}
}