//这个Shader是用来为了为其他Shader提供一些特殊的Pass
Shader "Gonbest/Legacy/SceneHelper"
{
	Properties
	{
	   	_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex("Base (RGB)", 2D) = "white" {}		
		_MyShadowMap("Shadow map", 2D) = "white" {}      //阴影贴图
		_ShadowIntensity("Shadow Intensity",float) = 1  //阴影强度
		_ShadowFadeFactor("Shadow Fade Factor",float) = 0 //阴影被材质影响消隐的效果
        _DiffuseColor("EmissiveColor",Color) = (0.7,0.7,0.7,0)
		_ISUI("(> 0.5) is ui",float) = 0
	}
	CGINCLUDE

		#include "../Include/Base/CommonCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"        
		#include "../Include/Indirect/Lightmap&SHLightCG.cginc"

		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;		
        uniform float4 _DiffuseColor;		
		uniform float _ISUI;
				
		struct v2f_lit
		{
			float4 pos 		: POSITION;
			half4 uv 		: TEXCOORD0;					
			float3 wn	    : TEXCOORD1;
			float4 wpos     : TEXCOORD2;
			GONBEST_FOG_COORDS(3)			
			GONBEST_SHADOW_COORDS(4)
            GONBEST_SH_COORDS(5)
			UNITY_VERTEX_INPUT_INSTANCE_ID		
			
		};
		
		//通用功能的vert
		v2f_lit vert_lit(appdata_full v)
		{
			UNITY_SETUP_INSTANCE_ID(v);
			v2f_lit o = (v2f_lit)0;
			o.pos = UnityObjectToClipPos(v.vertex);
            
			o.wn = UnityObjectToWorldNormal(v.normal);				
			o.wpos = mul(unity_ObjectToWorld, v.vertex);

			o.uv.xy =TRANSFORM_TEX(v.texcoord, _MainTex);
            o.uv.zw = GONBEST_CALC_LIGHTMAP_UV(v.texcoord1.xy);	
			GONBEST_TRANSFER_SH(o,o.wn, o.wpos);
			//阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,o.wpos,v.texcoord1);			
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.pos, o.wpos.xyz);	
			UNITY_TRANSFER_INSTANCE_ID(v, o);		
			return o;
		}

		//通用的frag
		fixed4 frag_lit(v2f_lit i) : COLOR
		{
			UNITY_SETUP_INSTANCE_ID(i);
			fixed4 mainTex = tex2D(_MainTex, i.uv.xy);					
			//处理颜色值
			GONBEST_APPLY_COLOR_MULTIPLIER(mainTex)
			//应用AlphaTest
			GONBEST_APPLY_ALPHATEST(mainTex)
			float3 emissive = mainTex.xyz ;//* _DiffuseColor;            
			
			mainTex.rgb = 0;            
            mainTex.rgb += emissive.rgb;
			
            //间接散射光处理
			float3 indirectDiff = (float3)1;
			GONBEST_APPLY_SH_COLOR(i,i.wn,i.wpos,indirectDiff); 
			GONBEST_APPLY_LIGHTMAP_COLOR(i.uv.zw,indirectDiff);

			//这里判断是否使用了探针和Lightmap
			float useSHorLIGHTMAP = step(0.001,indirectDiff.x+indirectDiff.y+indirectDiff.z);
			indirectDiff = lerp((float3)1,indirectDiff,useSHorLIGHTMAP);

			//阴影处理 						
			indirectDiff *= GONBEST_DECODE_SHADOW_VALUE(i,i.wpos);		
			fixed isui = step(0.5, _ISUI);
			//应用lightmap
			mainTex.rgb = lerp(mainTex.rgb * indirectDiff, mainTex.rgb, isui);		
			//对应模型雾的颜色
			GONBEST_APPLY_FOG_CHECK_UI(i, mainTex, isui);
#if defined(_GONBEST_SPEC_ALPHA_ON)
			mainTex.a = 0;
#endif
			return  mainTex;
		}
		/***************************************************************************/
		
	ENDCG
	
	SubShader
	{ 
		Pass
		{  
			//这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON 
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF      
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH   
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST&ALPHATEX"
			////Tags { "LightMode" = "ForwardBase" }			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON	
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing	
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON		
			ENDCG
		}

       
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog		
			#pragma multi_compile_instancing	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND&ALPHATEX"
			////Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest						
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   							
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing		
			
			ENDCG
		}

     
		Pass
		{  //这个Pass使用lightmap和使用阴影 -- 这里使用Alpha贴图
			Name "LIGHTMAP&ALPHATEX"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影-- 这里使用Alpha贴图
			Name "NOLIGHTMAP&ALPHATEX"
			////Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest						
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   							
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
   
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST"
			////Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   						
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
     
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHATEST&DOUBLEFACE"
			Tags { "LightMode" = "ForwardBase" }
			Cull OFF
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHATEST&DOUBLEFACE"
			////Tags { "LightMode" = "ForwardBase" }
			Cull OFF
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   						
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP&ALPHABLEND"
			Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
            #pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP&ALPHABLEND"
			////Tags { "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON				
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   							
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			ENDCG
		}

       
		
		Pass
		{  //这个Pass使用lightmap和使用阴影
			Name "LIGHTMAP"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile _GONBEST_SHADOW_ON _GONBEST_SHADOW_OFF			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON						
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF            
			#pragma multi_compile _GONBEST_INDIRECT_DIFFUSE_ON
			#pragma multi_compile LIGHTMAP_ON LIGHTPROBE_SH
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON	
			ENDCG
		}
		
		Pass
		{	//这个Pass不使用lightmap和不使用阴影
			Name "NOLIGHTMAP"
			////Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert_lit
			#pragma fragment frag_lit
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_HEIGHT_FOG_ON _GONBEST_HEIGHT_FOG_OFF
			#pragma multi_compile _GONBEST_CUSTOM_SHADOW_ON
			#pragma multi_compile SHADOWS_SCREEN   							
			#pragma multi_compile_fog	
			#pragma multi_compile_instancing	
			#pragma multi_compile _GONBEST_SPEC_ALPHA_ON		
			ENDCG
		}

      
	}
}