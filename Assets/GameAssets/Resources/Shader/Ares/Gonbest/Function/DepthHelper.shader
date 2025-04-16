/*===============================================================
Author:gzg
Date:2019-12-03
Desc:深度信息渲染的处理
=================================================================*/
Shader "Gonbest/Function/DepthHelper"
{
	Properties
	{
       

	}
	CGINCLUDE
		uniform sampler2D _MainTex;
		uniform half4 _MainTex_ST;
		#include "UnityCG.cginc"
		#include "../Include/Utility/WidgetUtilsCG.cginc"
				
		struct vertexdata
		{
			float4 vertex : POSITION;
			float4 texcoord:TEXCOORD0;
		};

		struct v2f
		{
			float4 pos : SV_POSITION;			
			float2 depth: TEXCOORD0;
			float2 uv : TEXCOORD1;
		};

		v2f vert( vertexdata v )
		{
			v2f o = (v2f)0;
			o.pos = UnityObjectToClipPos( v.vertex );
			o.uv = v.texcoord.xy;
			o.depth = o.pos.zw;
			return o;
		}

		fixed4 frag(v2f i) : COLOR
		{
			fixed d = (i.depth.x / i.depth.y);
			return fixed4(d, d, d, 1.0);
		}

		//写深度的处理
		fixed4 frag_write_z_a(v2f i): COLOR
		{			
			fixed4 color = tex2D(_MainTex,i.uv) ;		
			GONBEST_APPLY_ALPHATEST_VAL(color.a)
			return float4(1,1,1,0);
		}
	ENDCG
    SubShader
    {
		Pass
		{		
			//先写深度
			//这个Pass用处是写ZBuffer和Alpha信息,不写颜色信息
			//好处是,在pixelshader部分改变ZBuffer了,所以只能Late-Z,但是pixelshader的语句简单,所以能提高效率
		    Name "ONLYWRITEDEPTH&ALPHATEST"
			Tags  { "Queue" = "AlphaTest"  "RenderType" = "TransparentCutout" }			
			ZWrite On
			ZTest Less	
			ColorMask 0		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_write_z_a		
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			ENDCG
		}	

        Pass
		{	//只写深度		
			Name "ONLYWRITEDEPTH"	
			ZWrite On
			ColorMask 0
		}		

        Pass
		{//获取一个深度图
			Name "DEPTH"
			ZTest LEqual
			ZWrite On
			Cull Back
			Lighting Off
			Fog {Mode Off}
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG
		}
    }
}