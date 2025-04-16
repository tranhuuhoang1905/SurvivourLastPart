/*===============================================================
Author:gzg
Date:2020-02-12
Desc:这个Shader是用于只展示lightmap的渲染,
=================================================================*/
Shader "Gonbest/FallBack/FBWithShadowMapAlpha"
{
	Properties
	{
	
	}
	CGINCLUDE				
        #include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
        #include "../Include/Utility/RainUtilsCG.cginc"
        #include "../Include/Utility/PixelUtilsCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"        
        #include "../Include/Base/EnergyCG.cginc"
        #include "../Include/Specular/GGXCG.cginc"
        #include "../Include/Base/FresnelCG.cginc"
        #include "../Include/Specular/BeckmannCG.cginc"		
		#include "../Include/Indirect/Lightmap&SHLightCG.cginc"

		/*****************************带有lightmap的处理(分开了-_-!,这TM就是一个坑,lightmap处理好像不能放到一个宏判断中.)**********************************************/
		struct v2f_lit
		{
			float4 pos 		    : POSITION;
			float4 uv 		    : TEXCOORD0;			
			float4 wt 			: TEXCOORD1;
			float4 wb 			: TEXCOORD2;
			float4 wn 			: TEXCOORD3;
			GONBEST_FOG_COORDS(4)			
			GONBEST_SHADOW_COORDS(5)		
		};
		
		//通用功能的vert
		v2f_lit vert_lit(appdata_full v)
		{
			v2f_lit o = (v2f_lit)0;
            float4 ppos,wpos;
			float3 wt,wn,wb;    
			GetVertexParameters(v.vertex, v.tangent, v.normal, ppos, wpos, wn, wt, wb);
			o.pos = ppos;
			o.wt = float4(wt,wpos.x);        
			o.wb = float4(wb,wpos.y);
			o.wn = float4(wn,wpos.z);	
			//阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);			
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.pos, wpos);	

			return o;
		}
       
		//通用的frag
		fixed4 frag_lit(v2f_lit i) : COLOR
		{
			//间接散射光处理
			float3 indirectDiff = (float3)0;
            float3 P = float3(i.wt.z,i.wb.z,i.wn.z);          
            float shadow = GONBEST_DECODE_SHADOW_VALUE(i,P);	
            float4 outColor = float4(indirectDiff,step(shadow,0.5)); 
			return  outColor;
		}
		/***************************************************************************/
	ENDCG
	
	SubShader
	{ 
        Tags {"Queue"="Transparent+50" "IgnoreProjector"="True" "RenderType"= "Opaque" "GonbestBloomType"="BloomMask"}		
		Pass
		{              
			//这个Pass使用lightmap和使用阴影			
			Tags { "LightMode" = "ForwardBase" }	
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha				
			Cull Back
			ZWrite Off					
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON	
			#pragma multi_compile _GONBEST_SHADOW_ON		
			#pragma target 3.0	
			ENDCG
		}
	}
}