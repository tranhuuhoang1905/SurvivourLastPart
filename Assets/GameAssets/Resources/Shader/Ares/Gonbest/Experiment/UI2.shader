﻿Shader "UI/UI2"
{
	Properties
	{
		_MainTex("Sprite Texture", 2D) = "white" {}
		_Noise("_Noise Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		//My
		_Speed("速度",Range(0,1)) = 1
		_Fill("高度",Range(0,1)) = 1
		_Conc("浓度",Range(1,5)) = 1
		_Trans("透明度",Range(0,1)) = 1
		_BlendX("混合贴图X",2D) = "white" {}
		_BlendY("混合贴图Y",2D) = "white" {}

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		/*
		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}
		*/
		Cull Off
		Lighting Off
		ZWrite Off
		//ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
		//ColorMask[_ColorMask]

		Pass
		{
			Name "Default"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#define PI 3.1415926

			struct appdata_t
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
			float _Speed;
			float _Fill;
			float _Conc;
			float _Trans;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;

				OUT.color = float4(1,0,0,1) *_Color;
				return OUT;
			}

			sampler2D _MainTex;
			sampler2D _Noise;
			sampler2D _GrabTexture;
			sampler2D _BlendX;
			sampler2D _BlendY;

			fixed4 frag(v2f IN) : SV_Target
			{
				half2 uv = IN.texcoord;
				half4 col = IN.color;
				_Speed = _Speed*0.1;
				_Conc = (_Conc*-1) + 6;

				//采样噪声图
				half4 no1 = tex2D(_Noise, uv + _Time.xz*_Speed);
				half4 no2 = tex2D(_Noise, uv - _Time.zx*_Speed);
				half4 no3 = tex2D(_Noise, uv - _Time.yz*_Speed);

				if (_Fill - uv.y < 0.02) {
					_Color *= 20;					
					_Color.b = 0;
					_Color.a = sin(_Time.y%PI);
				}

				col.a -= no1.x*no2.x*no3.x*_Conc;
				col.a = uv.y > _Fill ? 0 : col.a;
				col.a *= _Trans;

				half4 color = (tex2D(_MainTex, uv)*tex2D(_BlendX, float2(no1.x,no2.x))*tex2D(_BlendY, uv*float2(no2.x,no3.x))*_Color);
				//color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				color.a *= col.a;				
				#ifdef UNITY_UI_ALPHACLIP
					clip(color.a - 0.001);
				#endif

				return color;
			}
			ENDCG
		}
	}
}