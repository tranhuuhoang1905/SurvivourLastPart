// Upgrade NOTE: replaced 'mul(GONBEST_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//运行时T4M的Shader处理
Shader "Gonbest/Experiment/T4MPassHelper_BigMap_Normal"
{
	Properties
	{	
		_Color("_Color",Color)	= (0.5 , 0.5, 0.5 , 1)
		_MainTex ("MainTex", 2D) = "white" {}
		_IndexTex ("IndexTex", 2D) = "white" {}
		_BlendTex ("_BlendTex", 2D) = "white" {}
		_TileSizeTex ("TileSizeTex", 2D) = "white" {}
		_NormalTex ("NormalTex", 2D) = "white" {}
		_MixTex ("MixTex", 2D) = "white" {}		
		_NormalScale("NormalScale",Range(0,5)) = 1		
		_Metallic("Metallic",Range(0,1)) = 0.1
		_Smoothness("Smoothness",Range(0,1)) = 0.1	
		_SpecularPower("SpecularPower",Range(0,10)) = 0.5			
		_EnvCube("Cube",Cube)= "white"{}	
		_TileSize("TileSize",Vector) = (20,20,0,0)
		_EnvInfo("_EnvInfo",vector)=(0,0,0,0)
				
	}
	
	CGINCLUDE	
		#include "../Include/Base/CommonCG.cginc"	
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Shadow/ShadowCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
		#include "../Include/Indirect/EnvBRDFCG.cginc"

		uniform float4 _Color;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform sampler2D _IndexTex;
		uniform sampler2D _BlendTex;
		uniform sampler2D _TileSizeTex;	
		uniform sampler2D _NormalTex;
		uniform sampler2D _MixTex;		
		uniform samplerCUBE _EnvCube;
		uniform float _NormalScale;		
		uniform float _AO;
		uniform float _SpecularPower;			
		uniform float2 _TileSize;
		uniform float _Metallic;
		uniform float _Smoothness;
		uniform float4 _EnvInfo;
		struct v2f
		{
			float4 vertex 		: POSITION;			
			half4 uv			: TEXCOORD0;				
			float4 wPos			:TEXCOORD1;
			float3 wNormal		:TEXCOORD2;
			float3 wTangent		:TEXCOORD3;
			float3 wBinormal	:TEXCOORD4;
			GONBEST_SHADOW_COORDS(5)	
			GONBEST_FOG_COORDS(6)
		};		


		//顶点处理程序
		v2f vert (appdata_full v)
		{
			v2f o = (v2f)0;
			o.vertex = UnityObjectToClipPos( v.vertex );		
			o.uv.xy = v.texcoord;
			//Lightmap的处理
			o.uv.zw = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			o.wPos = mul(unity_ObjectToWorld,v.vertex);
			//o.wPos.w = r1.z;			
			o.wPos.w = o.vertex.z;
			o.wNormal = GBNormalizeSafe(mul(float4(v.normal.xyz,0),unity_WorldToObject).xyz);
			o.wTangent = GBNormalizeSafe(mul(unity_ObjectToWorld,float4(v.tangent.xyz,1)).xyz);
			o.wBinormal = GBNormalizeSafe(cross(o.wNormal,o.wTangent) * v.tangent.w);
			//阴影处理
			GONBEST_TRANSFER_SHADOW(o,o.wPos,v.texcoord1);			
			//获取雾的采样点
			GONBEST_TRANSFER_FOG(o, o.vertex,o.wPos.xyz);		
			return o;
		}

		//GGX的正态分布函数
		inline float GGX_D(in float Roughness/*粗糙度*/, float NoH/*N和H的dot*/)
		{
			float m2= Roughness*Roughness + 0.0002;
			m2 *= m2;		 		 
			float D=(NoH*m2 - NoH) * NoH + 1;				 
			D = D*D + 1e-06;
			return 0.25 * m2 / D;
		}
		half GetRoughness_Ground(in half Smoothness,in float3 N)
		{
		//这里应该是判断是否使用EnvInfo
			half rain = _EnvInfo.x;
			rain = 1 - rain * saturate(N.y * 0.7 + 0.4 * rain);
			return rain * (1- Smoothness);
		}

		//通过Index纹理,把两张图片的UV值和他们的混合系数读取出来.
		void UnPackIndex(half2 iUV, half2 tileCnt, float depth, out half4 uv0, out half4 uv1, out half blend)
		{
			//采样Index纹理
			float3 index= tex2D(_IndexTex, iUV.xy).xyz;

			//颜色分量z表示混合值
			blend= tex2D(_BlendTex,iUV.xy).b;

			float4 c = float4(0, 0, 0, 0);
			//一个颜色分量的低4位是表示纹理所在坐标的y信息,高4位是表示纹理所在坐标的x信息.
			c.yw = floor(index.xy * 16);
			c.xz = floor(index.xy * 256) - 16 * c.yw;

			//这里参数的意义
			//0.25 = 1/4; //我们这里大图行列的张数是4x4的16张图组合的.
			//0.5 = 1/2;  //我们这里的大图是行列张数2x2的4张图组合的.
			c *= 0.25;				

			float4 tc = float4(tileCnt, tileCnt);
			/*
			#if _USE_T4M_TILE_TEX_ON
				float4 tc1 = tex2D(_TileSizeTex,c.xy);
				float4 tc2 = tex2D(_TileSizeTex,c.xy);				
				float4 tc = float4(tc1.xy*100, tc2.xy*100);
			#else
				float4 tc = float4(tileCnt, tileCnt);
			#endif
			*/
			//定义的一张纹理大小为256,而纹理的每个边有8像素的边框,用于解决边缘误差导致读取纹理错误的问题.
			//边宽: 0.03125 = 8 / 256;
			//有效宽度: 0.9375 = 1- 0.03125 * 2				
			tc = frac(iUV.xyxy * tc) * 0.9375 + 0.03125;
			tc *= 0.25;
			//这里把索引信息和平铺信息加在一起获得uv信息.
			c = c + tc;

			//或者mipmap的采样层次 -- 根据wpos.w保存的是深度depth信息.
			half mipLevel = min(depth * 3, 3);

			//组合出tex2Dlod的uv读取参数
			uv0 = half4(c.xy, mipLevel, mipLevel);
			uv1 = half4(c.zw, mipLevel, mipLevel);
		}

		#define GONBEST_SAMPLE_CUBE_IBL_EX(rdir,roughness,clr) \
				half __lod = roughness /0.17;\
				half3 __R = rdir;\
				half __sign = step(0,__R.z);\
				half __sign2 = step(0,__R.z) * 2 - 1;\
				__R.xy /= (__R.z * __sign2 + 1);\
				__R.xy = __R.xy * half2(0.25,-0.25) + 0.25;\
				__R.xy = 0.5 * __sign + __R.xy;\
				half4 __env = texCUBEbias(_EnvCube, half4(__R,__lod));\
				__env.rgb = __env.rgb * (__env.a *__env.a) ;\
				clr.xyz *= __env.rgb;

		fixed4 frag(v2f i) : COLOR
		{					
			half roughness = 1;			 			
			half blend=0;
			half4 uv0;
			half4 uv1;
			float depth = saturate(exp2(-i.wPos.w * 10 / log2(2)));			
			//depth = depth * depth * 2;
			UnPackIndex(i.uv.xy, _TileSize.xy, depth, uv0, uv1, blend);
				
			//纹理读取	
			half4 albedo0= tex2Dlod(_MainTex, uv0);
			//(albedo0)*=(albedo0);
			half4 albedo1=tex2Dlod(_MainTex, uv1);
			//(albedo1)*=(albedo1);			
			half4 color = lerp(albedo1,albedo0,blend);;

			//法线贴图处理
			float3 norm = tex2Dlod(_NormalTex, uv0);
			norm = lerp(tex2Dlod(_NormalTex, uv1),norm,blend);
			float3 N = 2*norm - 1;
			N.xy *= _NormalScale;
			N = GBNormalizeSafe(N.x * i.wTangent + N.y * i.wBinormal + N.z * i.wNormal.xyz);

			//获取光滑度
			#if _USE_T4M_MIXX_TEX_ON
				//使用mixx纹理
				half3 mixx=((blend)*(tex2Dlod(_MixTex, uv0)));
				mixx= lerp(tex2Dlod(_MixTex, uv1),mixx,blend);
				half Smoothness = mixx.r;
			#else
				//直接使用albedo的alpha分量
				float Smoothness = _Smoothness;
			#endif
			roughness = GetRoughness_Ground(Smoothness,N);
			
			//处理灯光
			float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz );
			float3 V = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - i.wPos.xyz);
			float3 H = GBNormalizeSafe(L+V);
			float ndl = dot(N,L);			
			float3 rdir = reflect(V,N).xyz;	

			float3 envClr = color.rgb;

			GONBEST_SAMPLE_CUBE_IBL_EX(rdir,roughness,envClr)

			envClr = EnvBRDFApprox(envClr,roughness,saturate(dot(N,V)));			

			fixed3 diff =  (1 - _Metallic) * 0.3185;
			fixed3 spec = GGX_D(roughness,saturate(dot(N,H))) * _SpecularPower;

			color.rgb += envClr  + (diff + spec)* ndl * _LightColor0.rgb ;
			color.rgb *= _Color;
			//应用lightmap
			//color.rgb *= DecodeLightmap( GONBEST_SAMPLE_TEX2D( unity_Lightmap, i.uv.zw));
			//应用阴影
			GONBEST_APPLY_SHADOW(i,i.wPos,color);						
			//对应模型雾的颜色
			GONBEST_APPLY_FOG(i, color);
			return color ;
		}		
	ENDCG

	SubShader
	{	
		Lighting Off
		ZWrite On
		Pass
		{	
			Name "RUNTIME"					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile _USE_SHADOW_OFF _USE_SHADOW_ON	
			#pragma multi_compile _USE_T4M_TILE_TEX_OFF _USE_T4M_TILE_TEX_ON
			#pragma multi_compile _USE_T4M_MIXX_TEX_OFF _USE_T4M_MIXX_TEX_ON
			#pragma multi_compile _USE_ENV_CUBE_ON
			#pragma multi_compile_fog
			ENDCG
		}			
	}
}