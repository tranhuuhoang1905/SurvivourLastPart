Shader "Gonbest/Legacy/ParticleHelper"
{
	Properties
	{	
        _Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex("Base (RGB)", 2D) = "white" {}			
		_ScrollSpeed ("scroll(x,y),a(z) ", Vector) = (2,2,1,-1)
		_MaskTex("MaskTex (RGB)", 2D) = "white" {}	
		_DissolveTex("DissolveTex",2D) = "black"{}
		_DissolveSoft("DissolveSoft",Range(0,1)) = 0
        _Alpha("Alpha",range(0,1)) = 1
		_RimColor ("Rim Color", Color) = (0.5,0.5,0.5,0.5)
		_RimPower ("Rim Power", Range(0.0,5.0)) = 2.5
		_RimInnerColor ("RimInnerColor", Color) =  (0.5,0.5,0.5,0.5)	
        _RimInnerPower("RimInnerPower", Range(0.0,5.0)) = 2.5
        _AlphaPower("AlphaPower",Range(0.0,5.0)) = 1
		_NoiseTex("Distort Texture ( R )",2D) = "white"{}
		_TimeScale("Speed", range ( -1, 1 ) ) = 0
		_DistortScaleX( "Strength X", range ( 0, 1 ) ) = 0.1
		_DistortScaleY( "Strength Y", range ( 0, 1 ) ) = 0.1
		_Cutoff("Cutoff",range(0,1)) = 1
		_AlphaTestMaskTex("AlphaTestMaskTex (R)", 2D) = "white" {}	
		_AlphaTestColor ("AlphaTestColor", Color) = (1, 1, 1, 1)	
		_CtrlTexUseUV2("CtrlTexUseUV2",float) = 0
		_UseCustomData("UseCustomData(custom1.w)",float) = 0
		_UseClip("UseClip",float) = 0
		_ClipRect("ClipRect",Vector)= (-50000,-50000,50000,50000)		
	}	

	CGINCLUDE
		#include "../Include/Base/CommonCG.cginc"
		#include "../Include/Base/MathCG.cginc"
        #include "../Include/Utility/WidgetUtilsCG.cginc"
		#include "../Include/Utility/FlowUtilsCG.cginc"

		uniform sampler2D _MainTex;		
		uniform half4 _MainTex_ST;
		uniform half _Alpha;
		//控制图纹理使用第二套UV的属性
		uniform half _CtrlTexUseUV2;
		uniform half _UseCustomData;

		struct v2f
		{
			float4 vertex 	: POSITION;
			fixed4 color  	: COLOR;
			half4 uv 		: TEXCOORD0;
			float3 normal   : TEXCOORD1;
            float3 wpos     : TEXCOORD2;			
			GONBEST_DISSOLVE_COORDS(3)
			GONBEST_MASK_COORDS(4)
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};
		
		//顶点片段
		v2f vert(appdata_full v)
		{
			UNITY_SETUP_INSTANCE_ID(v);
			v2f o = (v2f) 0;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.color = v.color;	
            o.normal = mul(float4(v.normal.xyz,1),unity_WorldToObject).xyz;
            o.wpos = mul(unity_ObjectToWorld,v.vertex).xyz;			
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);			
			GONBEST_TRANSFER_DISSOLVE(v, o, _CtrlTexUseUV2, _UseCustomData);			
			GONBEST_TRANSFER_MASK(v,o);			
			GONBEST_TRANSFER_SCROLL_UV(v,o)
			UNITY_TRANSFER_INSTANCE_ID(v, o);
			return o;
		}
		//通用片段
		fixed4 frag(v2f i) : COLOR
		{
			UNITY_SETUP_INSTANCE_ID(i);
		    fixed4 mainColor = GONBEST_TEX_SAMPLE(_MainTex, GONBEST_DISTORT_UV(i.uv.xy)) ;
			GONBEST_APPLY_MASK(i,mainColor);
			GONBEST_APPLY_COLOR_MULTIPLIER(mainColor)
			mainColor.rgb *= i.color.rgb;
			float a = i.color.a * _Alpha;		
			GONBEST_APPLY_DISSOLVE(a);
			a *= GONBEST_APPLY_IN_CLID_RECT(i.wpos);
			mainColor.a *= a;					
			mainColor.a = saturate(mainColor.a);
			GONBEST_APPLY_ALPHATEST(mainColor);
			return mainColor;
		}
		
		//技能的片段
		fixed4 frag_skill(v2f i) : COLOR
		{
            UNITY_SETUP_INSTANCE_ID(i);
			fixed4 mainColor = GONBEST_TEX_SAMPLE(_MainTex, GONBEST_DISTORT_UV(i.uv.xy)) ;
			GONBEST_APPLY_SCROLL_UV(i,mainColor);
			GONBEST_APPLY_MASK(i,mainColor);			
			GONBEST_APPLY_COLOR_MULTIPLIER(mainColor)
			mainColor.rgb *= i.color.rgb;
			float a = i.color.a * _Alpha;		
			GONBEST_APPLY_DISSOLVE(a);	
			a *= GONBEST_APPLY_IN_CLID_RECT(i.wpos);
			mainColor.a *= a;			
			mainColor.rgb *= mainColor.a;
			GONBEST_APPLY_ALPHATEST(mainColor);
			return mainColor ;
		}
		
		//边缘颜色
		uniform float4 _RimColor;
		uniform float _RimPower;
		//内部边缘颜色
		uniform float4 _RimInnerColor;
		uniform float _RimInnerPower;
		//alpha的Power值
		uniform float _AlphaPower;	
		
		fixed4 frag_rim(v2f i):COLOR
		{
            UNITY_SETUP_INSTANCE_ID(i);
			fixed4 mainColor = GONBEST_TEX_SAMPLE(_MainTex, GONBEST_DISTORT_UV(i.uv.xy)) ;
            float3 N = GBNormalizeSafe(i.normal);
            float3 V = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
            float NoV = dot(N,V);
			//计算边缘颜色值
			float rim = 1-NoV * NoV;
			//处理内部颜色值
			fixed4 color = i.color;//fixed4(1,1,1,1); //默认为白色
			//处理内部颜色
			GONBEST_APPLY_COLOR_MULTIPLIER(color);
			//处理边缘颜色
			color.rgb += pow(rim,_RimPower) * _RimColor.rgb * _Alpha ;	
			//处理alpha的值
			color.a = pow(rim,_RimPower)*_Alpha;
			color.a = saturate(color.a);
			return color;
		}

		fixed4 frag_rim_multiply(v2f i):COLOR
		{
            UNITY_SETUP_INSTANCE_ID(i);
			fixed4 mainColor = GONBEST_TEX_SAMPLE(_MainTex, GONBEST_DISTORT_UV(i.uv.xy)) ;
            float3 N = GBNormalizeSafe(i.normal);
            float3 V = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
            float NoV = dot(N,V);
			//计算边缘颜色值
			float rim =1- NoV * NoV;
			//处理内部颜色值
			fixed4 color = mainColor * i.color;//fixed4(1,1,1,1); //默认为白色
			//处理内部颜色
			GONBEST_APPLY_COLOR_MULTIPLIER(color);
			//处理边缘颜色
			color.rgb = lerp(color.rgb, _RimInnerColor.rgb ,pow(rim,_RimInnerPower) );	
			//处理边缘颜色			
			color.rgb = lerp(color.rgb, _RimColor.rgb ,pow(rim,_RimPower));			
			//处理alpha的值
			color.a = lerp(_AlphaPower, color.a, pow(rim,_RimPower));
			float a = _Alpha;			
			GONBEST_APPLY_DISSOLVE(a);	
			color.a = lerp(a ,color.a, _Alpha);		
			color.a = saturate(color.a);
			return color;
		}


	ENDCG

	SubShader
	{
		ZWrite Off
		Cull Off
		Lighting Off		
		//ColorMask RGB
		//-------------------Addtive---------------------------//
		Pass
		{	//用于作为覆盖物
			Name "COMMON&ALPHATEX&ADD&OVERLAY"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha		
		    ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		Pass
		{	//用于作为覆盖物
			Name "COMMON&ADD&OVERLAY"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag						
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		
		
		Pass
		{	//Addtive的Shader
			Name "COMMON&ALPHATEX&ADD"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		Pass
		{	//Addtive的Shader
			Name "COMMON&ADD&MASK"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_MASK_ON			
			#pragma multi_compile _GONBEST_MASK_ST_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		Pass
		{	//Addtive的Shader
			Name "COMMON&ADD"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			#pragma multi_compile_instancing	
			ENDCG
		}

		Pass
		{	//Addtive的Shader,溶解效果 ,这里是one+one
			Name "COMMON&ADD&DISSOLVE"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha	
			ZWrite Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_DISSOLVE_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}

		Pass
		{	//Addtive的Shader,扭曲效果
			Name "COMMON&ADD&DISTORT"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_UV_DISTORT_ON
			#pragma multi_compile _GONBEST_MASK_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{	//Addtive的Shader,扭曲效果
			Name "COMMON&ADD&ALPHATESTMASK"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_ALPHA_TEST_ON
			#pragma multi_compile _GONBEST_ALPHA_TEST_MASK_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		
		
		//-------------------Blend---------------------------//
		Pass
		{	//用于作为覆盖物
			Name "COMMON&ALPHATEX&BLEND&OVERLAY"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON	
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{	//用于作为覆盖物
			Name "COMMON&BLEND&OVERLAY"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag				
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			#pragma multi_compile_instancing	
			ENDCG
		}
		Pass
		{	//Blend的Shader
			Name "COMMON&ALPHATEX&BLEND"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			#pragma multi_compile_instancing
			ENDCG
		}
		Pass
		{	//Addtive的Shader
			Name "COMMON&ALPHATEX&BLEND&MASK"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_MASK_ON
			#pragma multi_compile _GONBEST_MASK_ST_ON			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		Pass
		{	//Addtive的Shader
			Name "COMMON&BLEND&MASK"
			Blend SrcAlpha One,Zero OneMinusSrcAlpha					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_MASK_ON
			#pragma multi_compile _GONBEST_MASK_ST_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			#pragma multi_compile_instancing	
			ENDCG
		}
		Pass
		{	//Blend的Shader
			Name "COMMON&BLEND"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}

		Pass
		{	//Blend的Shader
			Name "COMMON&BLEND&DISSOLVE"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_DISSOLVE_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}

		
		Pass
		{	//Addtive的Shader,扭曲效果
			Name "COMMON&BLEND&DISTORT"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON			
			#pragma multi_compile _GONBEST_UV_DISTORT_ON
			#pragma multi_compile _GONBEST_MASK_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
	
		//-------------------Multiply---------------------------//
		Pass
		{	//Multiply的Shader
			Name "COMMON&ALPHATEX&MULTIPLY"
			Blend Zero SrcColor,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{	//Multiply的Shader
			Name "COMMON&MULTIPLY"
			Blend Zero SrcColor,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}

		Pass
		{	//Multiply的Shader
			Name "COMMON&MULTIPLY&DISSOLVE"
			Blend Zero SrcColor,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_DISSOLVE_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}

		
		//-------------------Skill:在与场景混合时,颜色不会太爆(颜色互补)-------------//
		Pass
		{	//技能的特效Shader
			Name "SKILL&MASK"
			Blend OneMinusDstColor One,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_skill
					
			#pragma multi_compile _GONBEST_MASK_ON
			#pragma multi_compile _GONBEST_MASK_ST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{	//技能的特效Shader
			Name "SKILL&MASK&ALPHATEX"
			Blend OneMinusDstColor One,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_skill
					
			#pragma multi_compile _GONBEST_MASK_ON
			#pragma multi_compile _GONBEST_MASK_ST_ON
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		
		Pass
		{	//技能的特效Shader
			Name "SKILL"
			Blend OneMinusDstColor One,Zero OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_skill
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		Pass
		{	//技能的特效Shader
			Name "SKILL&ALPHATEX"
			Blend OneMinusDstColor One,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_skill
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_ALPHA_TEX_ON
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}

		Pass
		{	//技能的特效Shader
			Name "SKILL&DISSOLVE"
			Blend OneMinusDstColor One,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_skill
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_DISSOLVE_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}

		Pass
		{	//技能的特效Shader
			Name "SKILL&DISTORT"
			Blend OneMinusDstColor One,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_skill
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_UV_DISTORT_ON
			#pragma multi_compile _GONBEST_MASK_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile_instancing
			ENDCG
		}
		Pass
		{	//技能的特效Shader
			Name "SKILL&DISTORT&SCROLLONE"
			Blend OneMinusDstColor One,Zero OneMinusSrcAlpha	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_skill
			
			#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON
			#pragma multi_compile _GONBEST_UV_DISTORT_ON
			#pragma multi_compile _GONBEST_MASK_ON	
			#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON
			#pragma multi_compile _GONBEST_ONE_SCROLL_UV_ON	
			#pragma multi_compile_instancing
			ENDCG
		}
		//-------------------Rim一个透明边缘光的特效---------------------//
		Pass
		{
			Name "BLEND&RIM"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			Cull Back
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag_rim
							
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
				#pragma multi_compile _GONBEST_NORMAL_ON	
				#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON		
				#pragma multi_compile_instancing
			ENDCG
		}

		Pass
		{
			Name "BLEND&RIM&MULTIPLY&DISSOLVE"
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha					
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag_rim_multiply
				#pragma multi_compile _GONBEST_COLOR_MULTIPLIER_ON	
				#pragma multi_compile _GONBEST_NORMAL_ON	
				#pragma multi_compile _GONBEST_2D_CLIP_RECT_ON	
			    #pragma multi_compile _GONBEST_DISSOLVE_ON
				#pragma multi_compile_instancing
			ENDCG
		}
	}
}