Shader "Gonbest/Experiment/FlowMapHair"
{

	Properties{
		_Color("Texture 1 Color", Color) = (1, 1, 1, 1)
		_Cutoff("Base Alpha cutoff", Range(0,.9)) = .5
		//	_Blend("Blend", Range(0, 1)) = 0

			_Texture1("Texture 1", 2D) = ""
		//_ColorA("Texture 1 Color", Color) = (1, 1, 1, 1)

	//	_Texture2("Texture 2", 2D) = ""
		//_ColorB("Texture 2 Color", Color) = (1, 1, 1, 1)

		_Normal("Normal Map", 2D) = "bump" {}
		_NormalScale("Normal Scale", Float) = 1.0

		_SpecGlossMap("Specular", 2D) = "white" {}
		_SpecularColor("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(0,1)) = 20

		_OcclusionMap("OcclusionMap", 2D) = "white" {}



		////////////////////////////       KK           //////////////////////////////////////////
				_KKFlowMap("FlowMap", 2D) = "white" {}
				//反射平滑
				_KKSmoot("Reflective Smoothness", Range(0.0, 1.0)) = 0.5
					//反射最大值
					_KKScale("Reflective Gray Scale", Range(0.0, 48.0)) = 5.0
					//主高光颜色
					_KKColorA("Primary Specular Color", Color) = (1.0, 1.0, 1.0)
					//主高光指数（程度）
					_KKScaleA("Primary Exponent", Range(1.0, 192.0)) = 64.0
					//主根位置
					_KKShiftA("Primary Root Shift", Range(-20.0, 20.0)) = 0.275
					//次高光颜色
					_KKColorB("Secondary Specular Color", Color) = (1.0, 1.0, 1.0)
					//次高光指数
					_KKScaleB("Secondary Exponent", Range(1.0, 192.0)) = 48.0
					//次根位置
					_KKShiftB("Secondary Root Shift", Range(-1.0, 1.0)) = -0.040
					//直接因素
					_KKA("Spec Mix Direct Factors", Vector) = (0.15, 0.10, 0.05, 0)
					//间接因素
					_KKB("Spec Mix Indirect Factors", Vector) = (0.75, 0.60, 0.15, 0)


	}

		SubShader{
			Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
			//Lighting off
			// Render both front and back facing polygons.
			Cull Off
					///////////////////////////////////////////////////////////////////////////
					////render any pixels that are more than [_Cutoff] opaque//////////////////
					////////////渲染超过[_cutoff]的不透明像素            //////////////////////
					///////////////////////////////////////////////////////////////////////////
							Pass{
								CGPROGRAM
					#pragma vertex vert 
					#pragma fragment frag

					#include "UnityCG.cginc"
					#include "UnityShaderVariables.cginc"
					#include "UnityStandardConfig.cginc"
					#include "UnityPBSLighting.cginc" // TBD: remove
					#include "UnityStandardUtils.cginc"
					#include "Lighting.cginc"
					#include "UnityStandardBRDF.cginc"
					#include "AutoLight.cginc"

					UnityIndirect ZeroIndirect()
					{
						UnityIndirect ind;
						ind.diffuse = 0;
						ind.specular = 0;
						return ind;
					}

					half3 WorldNormal(half4 tan2world[3])
					{
						return normalize(tan2world[2].xyz);
					}

					sampler2D _Texture1;
					sampler2D _Texture2;
					float4 _Texture1_ST;
					float4 _Texture2_ST;
					float _Cutoff;
					float _Blend = 0;
					float4 _Color;

					sampler2D _Normal;
					float _NormalScale;
					float4 _Normal_ST;

					float4 _SpecularColor;
					float _Gloss;
					sampler2D _SpecGlossMap;

					sampler2D _OcclusionMap;

					/////////////////////////////      kk             /////////////////////////////////////////
					sampler2D _KKFlowMap;
					half _KKSmoot;
					half _KKScale;
					half4 _KKColorA;
					half _KKScaleA;
					half _KKShiftA;
					half _KKPrimaryRootShift;
					half4 _KKColorB;
					half _KKScaleB;
					half _KKShiftB;
					half3 _KKA;
					half3 _KKB;

					struct appdata_t {
						float4 vertex : POSITION;
						float4 color : COLOR;
						float2 texcoord : TEXCOORD0;
						float3 normal :NORMAL;

						float4 tangent:TANGENT;
					};

					struct v2f {
						float4 vertex :POSITION;
						//float4 pos:SV_POSITION;

						float4 color : COLOR;
						float2 texcoord : TEXCOORD0;
						float4 uv:TEXCOORD3;

						float3 worldNormal:TEXCOORD1;
						float3 worldPos:TEXCOORD2;

						float3 lightDir:TEXCOORD4;
						float3 viewDir:TEXCOORD5;

						half4 tangentToWorldAndParallax[3]	: TEXCOORD6;	// [3x3:tangentToWorld | 1x3:viewDirForParallax]

					};


					v2f vert(appdata_t v)
					{
						v2f o;
						UNITY_INITIALIZE_OUTPUT(v2f, o);
						o.vertex = UnityObjectToClipPos(v.vertex);
						o.uv.xy = v.texcoord.xy*_Texture1_ST.xy + _Texture1_ST.zw;
						o.uv.zw = v.texcoord.xy* _Normal_ST.xy + _Normal_ST.zw;
						TANGENT_SPACE_ROTATION;
						o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
						o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
						o.color = v.color;
						o.texcoord = TRANSFORM_TEX(v.texcoord, _Texture1);
						o.worldNormal = UnityObjectToWorldNormal(v.normal);
						o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

						//half3 normalWorld = NormalizePerPixelNormal(mul(NormalInTangentSpace(i_texcoord), i_tanToWorld));
						float3 normalWorld = UnityObjectToWorldNormal(v.normal);
						float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

						float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
						o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
						o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
						o.tangentToWorldAndParallax[2].xyz = (1 - tangentToWorld[2]);

						return o;
					}


					half4 frag(v2f i) : SV_Target //COLOR
					{
						fixed4 Tex1 = tex2D(_Texture1, i.texcoord);
						fixed4 Tex2 = tex2D(_Texture2, i.texcoord);

						//【法线】
						fixed3 tangenLightDir = normalize(i.lightDir);
						fixed3 tangenViewDir = normalize(i.viewDir);
						fixed4 packedNormal = tex2D(_Normal, i.uv.zw);
						fixed3 tangentNormal;
						tangentNormal = UnpackNormal(packedNormal);
						tangentNormal.xy *= _NormalScale;
						tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

						fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

						fixed3 NdotL = max(0, dot(tangentNormal, tangenLightDir));
						half nl = dot(tangentNormal, tangenLightDir);

						fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldNormal));

						fixed3 halfDir = normalize(tangenLightDir + tangenViewDir);

						fixed3 NdotH = max(0, dot(tangentNormal, halfDir));
						half nh = BlinnTerm(tangentNormal, halfDir);

						fixed4 col = lerp(Tex1, Tex2, _Blend);
						clip(col.a - _Cutoff);

						fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*col.rgb;

						fixed3 diffuse = _LightColor0.rgb*col.rgb*_Color* NdotL;



						half4 specGloss = tex2D(_SpecGlossMap, i.uv.xy);
						half roughness = 1 - specGloss.a;
						half sp = RoughnessToSpecPower(roughness);
						half specularTerm = pow(nh, sp);



						///////////////////////tanDir////////////////////
						half3 tangentToWorldMatrix = (i.tangentToWorldAndParallax[0].xyz, i.tangentToWorldAndParallax[1].xyz, i.tangentToWorldAndParallax[2].xyz);

						half3 tanFlow = tex2D(_KKFlowMap, i.uv.zw).xyz * 3;

						half3 worldTangent = mul(tangentToWorldMatrix, tanFlow);

						half3 normalWorldVertex = WorldNormal(i.tangentToWorldAndParallax);

						half3 tanDir = normalize(worldTangent + normalWorldVertex.xyz * _KKShiftA);
						half3 tanDir2 = normalize(worldTangent + normalWorldVertex.xyz * _KKShiftB);

						half th1 = dot(tanDir, halfDir);
						half th2 = dot(tanDir2, halfDir);

						UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

						half3 kkSTA = pow(sqrt(1.f - th1 * th1), _KKScaleA) * _KKColorA.rgb*_LightColor0.rgb;
						half3 kkSTB = pow(sqrt(1.f - th2 * th2), _KKScaleB) * _KKColorB.rgb*_LightColor0.rgb;
						half3 kkSpecTermBlinn = (specularTerm *_SpecularColor.rgb);
						half kkDirectFactor = min(1.f, Luminance(diffuse) + nl * atten);
						_KKA *= kkDirectFactor;

						half3 kkSpecTermDirect = kkSTA * _KKA.x + kkSTB * _KKA.y + kkSpecTermBlinn * _KKA.z *_LightColor0.rgb;
						half3 kkSpecTermIndirect = kkSTA * _KKB.x + kkSTB * _KKB.y + kkSpecTermBlinn * _KKB.z *_LightColor0.rgb;

						half occlusion = tex2D(_OcclusionMap, i.uv).g;

						//UnityIndirect indirect = ZeroIndirect();

						half3 color = half3(0.f, 0.f, 0.f);

						color = diffuse.rgb* (diffuse.rgb + _LightColor0.rgb* nl) + color + (kkSpecTermIndirect + kkSpecTermDirect) *occlusion;
						//color = diffuse.rgb+ color + (kkSpecTermIndirect + kkSpecTermDirect);// *occlusion;

						col.rgb = color + ambient + diffuse;
						return col;

					}
					ENDCG
					}





					///////////////////////////////////////////////////////////////////////////
					/////////////             阴影  de Pass              //////////////////////
					///////////////////////////////////////////////////////////////////////////
								Pass{

								Tags{ "LightMode" = "ShadowCaster" }

								ZWrite On ZTest LEqual





								CGPROGRAM




					#pragma target 3.0

					#pragma only_renderers d3d11 d3d9 opengl glcore

					#define UNITY_BRDF_PBS BRDF1_Unity_PBS_KK

					#pragma multi_compile _ _ALPHATEST_ON _ALPHABLEND_ON
					#pragma multi_compile_shadowcaster

					#pragma vertex vert
					#pragma fragment frag
					#include "UnityStandardShadow.cginc"


								struct appdata_t {
								float4 vertex : POSITION;
								float4 color : COLOR;
								float2 texcoord : TEXCOORD0;
							};

							struct v2f {
								float4 vertex : POSITION;
								float4 color : COLOR;
								float2 texcoord : TEXCOORD0;
							};

							sampler2D _Texture1;
							sampler2D _Texture2;
							float4 _Texture1_ST;
							float4 _Texture2_ST;
							//float _Cutoff;
							float _Blend;

							v2f vert(appdata_t v)
							{
								v2f o;
								o.vertex = UnityObjectToClipPos(v.vertex);
								o.color = v.color;
								o.texcoord = TRANSFORM_TEX(v.texcoord, _Texture1);
								return o;
							}

							//float4 _Color;
							half4 frag(v2f i) : COLOR
							{
								half4 col = lerp(tex2D(_Texture1, i.texcoord),tex2D(_Texture2, i.texcoord), _Blend);
								clip(col.a - _Cutoff);
								return col;
							}
								ENDCG
							}



						///////////////////////////////////////////////////////////////////////////
						////// render the semitransparent details.渲染半透明的细节   ////////////
						///////////////////////////////////////////////////////////////////////////

									Pass{
									Tags{ "RequireOption" = "SoftVegetation" }

									// Dont write to the depth buffer
									ZWrite off
								// Set up alpha blending
								Blend SrcAlpha OneMinusSrcAlpha
								CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag

					#include "UnityCG.cginc"
					#include "UnityShaderVariables.cginc"
					#include "UnityStandardConfig.cginc"
					#include "UnityPBSLighting.cginc" // TBD: remove
					#include "UnityStandardUtils.cginc"
					#include "Lighting.cginc"
					#include "UnityStandardBRDF.cginc"
					#include "AutoLight.cginc"


								UnityIndirect ZeroIndirect()
							{
								UnityIndirect ind;
								ind.diffuse = 0;
								ind.specular = 0;
								return ind;
							}
							half3 WorldNormal(half4 tan2world[3])
							{
								return normalize(tan2world[2].xyz);
							}



							sampler2D _Texture1;
							sampler2D _Texture2;
							float4 _Texture1_ST;
							float4 _Texture2_ST;
							float _Cutoff;
							float _Blend;
							float4 _Color;
							sampler2D _Normal;
							float _NormalScale;
							float4 _Normal_ST;
							float4 _SpecularColor;
							float _Gloss;
							sampler2D _SpecGlossMap;
							sampler2D _OcclusionMap;
							sampler2D _KKFlowMap;
							half _KKSmoot;
							half _KKScale;
							half4 _KKColorA;
							half _KKScaleA;
							half _KKShiftA;
							half _KKPrimaryRootShift;
							half4 _KKColorB;
							half _KKScaleB;
							half _KKShiftB;
							half3 _KKA;
							half3 _KKB;




							struct appdata_t {
								float4 vertex : POSITION;
								float4 color : COLOR;
								float2 texcoord : TEXCOORD0;
								float3 normal :NORMAL;
								float4 tangent:TANGENT;
							};

							struct v2f {
								float4 vertex :POSITION;
								//float4 pos:SV_POSITION;
								float4 color : COLOR;
								float2 texcoord : TEXCOORD0;
								float4 uv:TEXCOORD3;
								float3 worldNormal:TEXCOORD1;
								float3 worldPos:TEXCOORD2;
								float3 lightDir:TEXCOORD4;
								float3 viewDir:TEXCOORD5;
								half4 tangentToWorldAndParallax[3]	: TEXCOORD6;
							};



							v2f vert(appdata_t v)
							{
								v2f o;
								o.vertex = UnityObjectToClipPos(v.vertex);
								//o.vertex = UnityObjectToClipPos(UNITY_MATRIX_MVP,v.vertex);
								o.uv.xy = v.texcoord.xy*_Texture1_ST.xy + _Texture1_ST.zw;
								o.uv.zw = v.texcoord.xy* _Normal_ST.xy + _Normal_ST.zw;
								TANGENT_SPACE_ROTATION;
								o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
								o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
								o.color = v.color;
								o.texcoord = TRANSFORM_TEX(v.texcoord, _Texture1);
								//o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
								o.worldNormal = UnityObjectToWorldNormal(v.normal);
								o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
								//o.uv.xy = v.texcoord.xy*_Texture1_ST.xy + _Texture1_ST.zw;
								float3 normalWorld = UnityObjectToWorldNormal(v.normal);
								float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
								float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
								o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
								o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
								o.tangentToWorldAndParallax[2].xyz = (1 - tangentToWorld[2]);
								return o;
							}


							half4 frag(v2f i) : COLOR
							{
								/*	half4 col = lerp(tex2D(_Texture1, i.texcoord),tex2D(_Texture2, i.texcoord), _Blend)*_Color;
									clip(-(col.a - _Cutoff));*/

									fixed4 Tex1 = tex2D(_Texture1, i.texcoord);
									fixed4 Tex2 = tex2D(_Texture2, i.texcoord);


									//【法线】
									fixed3 tangenLightDir = normalize(i.lightDir);
									fixed3 tangenViewDir = normalize(i.viewDir);
									fixed4 packedNormal = tex2D(_Normal, i.uv.zw);
									fixed3 tangentNormal;
									tangentNormal = UnpackNormal(packedNormal);
									tangentNormal.xy *= _NormalScale;
									tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

									fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

									fixed3 NdotL = max(0, dot(tangentNormal, tangenLightDir));
									half nl = dot(tangentNormal, tangenLightDir);

									fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldNormal));

									fixed3 halfDir = normalize(tangenLightDir + tangenViewDir);

									fixed3 NdotH = max(0, dot(tangentNormal, halfDir));
									half nh = BlinnTerm(tangentNormal, halfDir);

									half4 col = lerp(tex2D(_Texture1, i.texcoord), tex2D(_Texture2, i.texcoord), _Blend)*_Color;
									clip(-(col.a - _Cutoff));

									fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*col.rgb;

									fixed3 diffuse = _LightColor0.rgb*col.rgb*_Color* NdotL;


									half4 specGloss = tex2D(_SpecGlossMap, i.uv.xy);
									half roughness = 1 - specGloss.a;
									half sp = RoughnessToSpecPower(roughness);
									half specularTerm = pow(nh, sp);


									///////////////////////tanDir////////////////////
									half3 tangentToWorldMatrix = (i.tangentToWorldAndParallax[0].xyz, i.tangentToWorldAndParallax[1].xyz, i.tangentToWorldAndParallax[2].xyz);

									half3 tanFlow = tex2D(_KKFlowMap, i.uv.zw).xyz * 3;

									half3 worldTangent = mul(tangentToWorldMatrix, tanFlow);

									half3 normalWorldVertex = WorldNormal(i.tangentToWorldAndParallax);

									half3 tanDir = normalize(worldTangent + normalWorldVertex.xyz * _KKShiftA);
									half3 tanDir2 = normalize(worldTangent + normalWorldVertex.xyz * _KKShiftB);

									half th1 = dot(tanDir, halfDir);
									half th2 = dot(tanDir2, halfDir);

									UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

									half3 kkSTA = pow(sqrt(1.f - th1 * th1), _KKScaleA) * _KKColorA.rgb*_LightColor0.rgb;
									half3 kkSTB = pow(sqrt(1.f - th2 * th2), _KKScaleB) * _KKColorB.rgb*_LightColor0.rgb;
									half3 kkSpecTermBlinn = specularTerm * _SpecularColor;
									half kkDirectFactor = min(1.f, Luminance(diffuse) + nl * atten);
									_KKA *= kkDirectFactor;

									half3 kkSpecTermDirect = kkSTA * _KKA.x + kkSTB * _KKA.y + kkSpecTermBlinn * _KKA.z *_LightColor0.rgb;
									half3 kkSpecTermIndirect = kkSTA * _KKB.x + kkSTB * _KKB.y + kkSpecTermBlinn * _KKB.z *_LightColor0.rgb;

									half occlusion = tex2D(_OcclusionMap, i.uv).g;


									UnityIndirect indirect = ZeroIndirect();

									half3 color = half3(0.f, 0.f, 0.f);

									color = diffuse.rgb* (indirect.diffuse + _LightColor0.rgb* nl) + color + (kkSpecTermIndirect + kkSpecTermDirect) *occlusion;

									col.rgb = color + ambient + diffuse;
									return col;


								}
									ENDCG
								}
				}
}
