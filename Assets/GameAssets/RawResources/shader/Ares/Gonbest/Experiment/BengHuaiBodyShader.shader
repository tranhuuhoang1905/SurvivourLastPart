Shader "Gonbest/Experiment/BengHuaiBodyShader"
{
	Properties
	{
		_Color("_Color",Color) = (1,1,1,1)
		_MainTex ("MainTex", 2D) = "white" {}
		_ShadowMask("_ShadowMask(主要是为了调整lightmap的y通道)",range(0,10)) = 1
		_Routhness("_Routhness(粗糙度)",range(0,10)) = 1
		_LightMapTex ("LightMapTex", 2D) = "white" {}		
		_FirstShadowMultColor("_FirstShadowMultColor",Color) = (0.9,0.76,0.8,1)		
		_SecondShadowMultColor("_SecondShadowMultColor",Color) = (0.9,0.76,0.8,1)
		_SecondShadow("_SecondShadow(0：第二阴影色,0.5：两个阴影色对半,1：第一阴影色)",range(0,1)) = 0.5
		_ShadowArea("_ShadowArea(0:阴影,0.5：半阴影半贴图色,1：全部贴图色)",range(0,1)) = 0.5
		

		_Shininess("_Shininess",float) = 10
		_SpecMulti("_SpecMulti",float) = 0.2
		_SpecularColor("_SpecularColor",Color) = (1,1,1,1)
		_lightProbColor("_lightProbColor",Color) = (0,0,0,0)
		_lightProbToggle("_lightProbToggle",float) = 0
		//_MaxOutlineZOffset("_MaxOutlineZOffset",float) = 1
		//_OutlineWidth("_OutlineWidth",float) = 0.07
		//_Scale("_Scale",float) = 0.01
		//_OutlineColor("_OutlineColor",Color) = (0.78,0.46,0.44,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque"  "GonbestBloomType"="BloomMask"}
		LOD 100
		
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "../Include/Base/MathCG.cginc"

			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;								
				float3 wpos:TEXCOORD1;
				float4 color:TEXCOORD2;
				float3 normal:TEXCOORD3;
				float3 diff:TEXCOORD4;
				float4 screenPos:TEXCOORD5;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _LightMapTex;
			uniform float _DitherAlpha;	
			uniform float _UsingDitherAlpha;
			uniform float _BloomFactor;
			uniform float4 _Color ;
			uniform float3 _FirstShadowMultColor ;
			uniform float _ShadowArea ;
			uniform float3 _SpecularColor ;			
			uniform float _SecondShadow ;
			uniform float3 _SecondShadowMultColor ;
			uniform float _Shininess;
			uniform float _SpecMulti;						
			uniform float4 _lightProbColor;
			uniform float _lightProbToggle;
			uniform float _ShadowMask;
			uniform float _Routhness;

			float4 test(v2f i)
			{
				float2 _u_xlat0 = {0, 0};
				float3 lightColor = {0, 0, 0};
				float3 mainColor =  {0, 0, 0};
				int _u_xlati0 = {0};
				uint2 _u_xlatu0 = {0, 0};
				bool _u_xlatb0 = {0};
				float4 _u_xlat1 = {0, 0, 0, 0};
				float3 _u_xlat16_2 = {0, 0, 0};
				float3 _u_xlat16_3 = {0, 0, 0};
				float3 _u_xlat4 = {0, 0, 0};
				float3 _u_xlat5 = {0, 0, 0};
				float _u_xlat16_5 = {0};
				int3 _u_xlati5 = {0, 0, 0};
				float3 _u_xlat16_7 = {0, 0, 0};
				bool2 _u_xlatb10 = {0, 0};
				float _u_xlat15 = {0};
				int _u_xlati16 = {0};
				float _u_xlat16_17 = {0};
				(lightColor.xyz = tex2D(_LightMapTex, i.uv.xy).xyz);
				(mainColor.xyz = tex2D(_MainTex, i.uv.xy).xyz);

				(_u_xlat16_2.x = (lightColor.y * i.color.x));  

				//_u_xlat5.z  = max(floor(i.color.x * lightColor.y +  0.90999997),0);
				(_u_xlat15 = ((i.color.x * lightColor.y) + 0.90999997));
				(_u_xlat15 = floor(_u_xlat15));
				(_u_xlat5.z = max(_u_xlat15, 0.0));

				//_u_xlati16 =  max(floor((i.color.x * lightColor.y) + i.diff) * 0.5 - _SecondShadow + 1),0)
				(_u_xlat16_7.x = ((i.color.x * lightColor.y) + i.diff));
				(_u_xlat16_7.x = ((_u_xlat16_7.x * 0.5) + (-_SecondShadow)));
				(_u_xlat16_7.x = (_u_xlat16_7.x + 1.0));
				(_u_xlat16_7.x = floor(_u_xlat16_7.x));
				(_u_xlat16_7.x = max(_u_xlat16_7.x, 0.0));
				(_u_xlati16 = int(_u_xlat16_7.x));

				//_u_xlat16_7.xyz = mainColor.xyz * _SecondShadowMultColor.xyz;
				(_u_xlat16_7.xyz = (mainColor.xyz * _SecondShadowMultColor.xyz));
				//_u_xlat16_3.xyz = mainColor.xyz * _FirstShadowMultColor.xyz;
				(_u_xlat16_3.xyz = (mainColor.xyz * _FirstShadowMultColor.xyz));

				//_u_xlat16_7.xyz = lerp(_u_xlat16_7,_u_xlat16_3,step(1,_u_xlati16))
				float3 s5 = {0, 0, 0};
				if ((int(_u_xlati16) != 0))
				{
					(s5 = _u_xlat16_3.xyz);
				}
				else
				{
					(s5 = _u_xlat16_7.xyz);
				}
				(_u_xlat16_7.xyz = s5);

				//_u_xlat5.x =  max(floor(1.5 - i.color.x * lightColor.y ),0);
				(_u_xlat5.x = (((-i.color.x) * lightColor.y) + 1.5));
				(_u_xlat5.x = floor(_u_xlat5.x));
				(_u_xlat5.x = max(_u_xlat5.x, 0.0));

				//_u_xlati5.xz = int2(_u_xlat5.xz));
				(_u_xlati5.xz = int2(_u_xlat5.xz));

				//(_u_xlat4.xy = (((lightColor.y * i.color.x) * float2(1.2, 1.25)) + float2(-0.1, -0.125)));
				(_u_xlat4.xy = ((_u_xlat16_2.xx * float2(1.2, 1.25)) + float2(-0.1, -0.125)));

				//_u_xlati5.x = int(max(floor((lerp(u_xlat4.x,u_xlat4.y,step(1,_u_xlati5.x)) + i.diff)*0.5 - _ShadowArea + 1.0),0));
				float s6 = {0};
				if ((_u_xlati5.x != 0))
				{
					(s6 = _u_xlat4.y);
				}
				else
				{
					(s6 = _u_xlat4.x);
				}    
				(_u_xlat16_2.x = s6);
				(_u_xlat16_2.x = (_u_xlat16_2.x + i.diff));
				(_u_xlat16_2.x = ((_u_xlat16_2.x * 0.5) + (-_ShadowArea)));
				(_u_xlat16_2.x = (_u_xlat16_2.x + 1.0));
				(_u_xlat16_2.x = floor(_u_xlat16_2.x));
				(_u_xlat16_2.x = max(_u_xlat16_2.x, 0.0));
				(_u_xlati5.x = int(_u_xlat16_2.x));

				//_u_xlat16_3.xyz = lerp(_u_xlat16_3.xyz, mainColor.xyz, step(1,_u_xlati5.x))
				float3 s7 = {0, 0, 0};
				if ((_u_xlati5.x != 0))
				{
					(s7 = mainColor.xyz);
				}
				else
				{
					(s7 = _u_xlat16_3.xyz);
				}
				(_u_xlat16_3.xyz = s7);


				//_u_xlat16_2.xyz = lerp(_u_xlat16_7.xyz, _u_xlat16_3.xyz, step(1,_u_xlati5.z))
				float3 s8 = {0, 0, 0};
				if ((_u_xlati5.z != 0))
				{
					(s8 = _u_xlat16_3.xyz);
				}
				else
				{
					(s8 = _u_xlat16_7.xyz);
				}
				(_u_xlat16_2.xyz = s8);

				//N
				(_u_xlat5.x = dot(i.normal.xyz, i.normal.xyz));
				(_u_xlat5.x = rsqrt(_u_xlat5.x));
				(_u_xlat1.xyz = (_u_xlat5.xxx * i.normal.xyz));

				//H
				(_u_xlat4.xyz = ((-i.wpos.xyz) + _WorldSpaceCameraPos.xyz));
				(_u_xlat5.x = dot(_u_xlat4.xyz, _u_xlat4.xyz));
				(_u_xlat5.x = rsqrt(_u_xlat5.x));
				(_u_xlat4.xyz = ((_u_xlat4.xyz * _u_xlat5.xxx) + _WorldSpaceLightPos0.xyz));
				(_u_xlat5.x = dot(_u_xlat4.xyz, _u_xlat4.xyz));
				(_u_xlat5.x = rsqrt(_u_xlat5.x));
				(_u_xlat4.xyz = (_u_xlat5.xxx * _u_xlat4.xyz));

				//spec = pow(max(dot(N,H),0),_Shininess);
				(_u_xlat16_17 = dot(_u_xlat1.xyz, _u_xlat4.xyz));
				(_u_xlat16_17 = max(_u_xlat16_17, 0.0));
				(_u_xlat16_17 = log2(_u_xlat16_17));
				(_u_xlat16_17 = (_u_xlat16_17 * _Shininess));
				(_u_xlat16_17 = exp2(_u_xlat16_17));

				//_u_xlat5.x = max(floor(1-lightColor.z - spec + 1),0);
				(_u_xlat16_5 = ((-lightColor.z) + 1.0));
				(_u_xlat16_5 = ((-_u_xlat16_17) + _u_xlat16_5));
				(_u_xlat5.x = (_u_xlat16_5 + 1.0));
				(_u_xlat5.x = floor(_u_xlat5.x));
				(_u_xlat5.x = max(_u_xlat5.x, 0.0));
				(_u_xlati5.x = int(_u_xlat5.x));

				//_u_xlat16_3.xyz = lightColor.x * _SpecMulti * _LightSpecColor.xyz;
				(_u_xlat16_3.xyz = (float3(float3(_SpecMulti, _SpecMulti, _SpecMulti)) * _SpecularColor.xyz));
				(_u_xlat16_3.xyz = (lightColor.xxx * _u_xlat16_3.xyz));

				//_u_xlat16_3.xyz = lerp(_u_xlat16_3.xyz,0,step(1,_u_xlati5.x))
				float3 s9 = {0, 0, 0};
				if ((_u_xlati5.x != 0))
				{
					(s9 = float3(0.0, 0.0, 0.0));
				}
				else
				{
					(s9 = _u_xlat16_3.xyz);
				}
				(_u_xlat16_3.xyz = s9);

				//_u_xlat16_2.xyz = (_u_xlat16_2.xyz + _u_xlat16_3.xyz) * _Color;
				(_u_xlat16_2.xyz = (_u_xlat16_2.xyz + _u_xlat16_3.xyz));
				(_u_xlat16_2.xyz = (_u_xlat16_2.xyz * _Color.xyz));

				//_u_xlat16_3.xyz = lerp(1, _lightProbColor.xyz,step(0.5,_lightProbToggle));
				(_u_xlatb0 = (!(!(0.5 < _lightProbToggle))));
				float3 s10 = {0, 0, 0};
				if (bool(_u_xlatb0))
				{
					(s10 = _lightProbColor.xyz);
				}
				else
				{
					(s10 = float3(1.0, 1.0, 1.0));
				}
				(_u_xlat16_3.xyz = s10);				
				return float4(_u_xlat16_2.xyz * _u_xlat16_3.xyz,_BloomFactor);
			;
			}
			
			v2f vert (appdata_full v)
			{
				v2f o;
				float4 wpos = mul(unity_ObjectToWorld,v.vertex);
				o.wpos = wpos.xyz/wpos.w;
				o.vertex = mul(UNITY_MATRIX_VP,wpos);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color = v.color;
				o.normal = GBNormalizeSafe(mul(v.normal.xyz,(float3x3)unity_WorldToObject));
				o.diff = saturate(dot(o.normal,_WorldSpaceLightPos0.xyz));
				float4 pos = o.vertex;
				pos.y = pos.y * _ProjectionParams.x;
				pos.xy = (pos.xy + float2(pos.w,pos.w)) * 0.5;
				o.screenPos.xyz = pos.xyz;
				o.screenPos.w = _DitherAlpha;				
				return o;
			}

			#include "../include/Base/RampCG.cginc"

			fixed4 frag (v2f i) : SV_Target
			{
				float3 diff = saturate(dot(i.normal,_WorldSpaceLightPos0.xyz));
				//return test(i);
				float3 lightColor = tex2D(_LightMapTex, i.uv).xyz;
				float3 mainColor = tex2D(_MainTex, i.uv).xyz;

				//灯光mask		
				float specStrength = lightColor.x;// lightColor.x ;
				float lightMask = lightColor.y*_ShadowMask;//i.color.x *
				float routhness = (1- lightColor.z)*_Routhness;

				//引用中第一和第二阴影的差值参数
				float shadowFactor = step(1,FloorStep(diff, 0.5, lightMask, _SecondShadow));// floor(lightMask + i.diff) * 0.5 - _SecondShadow + 1;

				float3 firstShadowColor = mainColor.xyz * _FirstShadowMultColor.xyz;	
				float3 secondShadowColor = mainColor.xyz * _SecondShadowMultColor.xyz;	

				float3 shadowColor = lerp(secondShadowColor,firstShadowColor,shadowFactor);
				

				//这里对于以0.5为分割线，对斜率做了修改
				float newlightmask = lerp(lightMask * 1.2 - 0.1, lightMask * 1.25 - 0.125,step(lightMask,0.5));// step(1, floor(1.5 - lightMask )));
				

				float firstMainFactor = step(1,FloorStep(diff, 0.5, newlightmask-0.1 , _ShadowArea)) ;//floor((newlightmask + i.diff ) * 0.5 - _ShadowArea + 1);

				
				float3 fColor1 = lerp(firstShadowColor, mainColor.xyz, firstMainFactor);

			    //lightMask < 0.1 ==> shadowColor;
				float3 fColor = lerp(shadowColor, fColor1, step(0.1, lightMask));	//step(1,max(floor(lightMask +  0.90999997),0))			
				
				float3 N = GBNormalizeSafe(i.normal);
				float3 H = GBNormalizeSafe(GBNormalizeSafe(_WorldSpaceCameraPos.xyz - i.wpos) + _WorldSpaceLightPos0.xyz);
				float spec = pow(max(dot(N,H),0),_Shininess);

				float specFactor = max(floor(routhness + 1 - spec ),0);

				float3 specColor = specStrength * _SpecMulti * _SpecularColor.xyz;

				specColor = lerp(specColor, 0, step(1 , specFactor));

				fColor = (fColor + specColor) * _Color;

				float3 probColor = lerp(1, _lightProbColor.xyz,step(0.5,_lightProbToggle));
				
				return fColor.xyzx;//float4(fColor * probColor,_BloomFactor);
			}
			ENDCG
		}

/*
		Pass
		{
			CGPROGRAM
			// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
			#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			
			struct v2f
			{
				float4 vertex : SV_POSITION;				
				float4 color:TEXCOORD0;
			};
			
			
			uniform float _MaxOutlineZOffset ;
			uniform float4 _OutlineColor ;
			uniform float _OutlineWidth ;			
			uniform float _Scale ;
			
			v2f vert (appdata_full v)
			{
				v2f o;
				float3 mv1 = float3(UNITY_MATRIX_MV[0].x,UNITY_MATRIX_MV[2].x,UNITY_MATRIX_MV[3].x);
				float3 mv2 = float3(UNITY_MATRIX_MV[0].y,UNITY_MATRIX_MV[2].y,UNITY_MATRIX_MV[3].y);
				float3 tangent = GBNormalizeSafe(float3(dot(v.tangent.xyz ,mv1),dot(v.tangent.xyz , mv2),0.001));

				float4 vpos = mul(UNITY_MATRIX_MV,v.vertex);

				float3 vv = GBNormalizeSafe(vpos.xyz);

				vv.xyz = vv.xyz *_MaxOutlineZOffset * _Scale;

				vv = (1 - 0.5 ) * vv.xyz +  vpos.xyz;//v.color.z

				vpos.x = sqrt((-vpos.z/unity_CameraProjection[1].y)/_Scale);

				float _u_xlat16_11 = _OutlineWidth * _Scale  * vpos.x; //* v.color.w

				vpos.xy = tangent.xy * _u_xlat16_11 + vv.xy;
				vpos.z = vv.z;
				o.vertex = mul(UNITY_MATRIX_P,vpos);
				o.color = _OutlineColor;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return i.color;
			}
			ENDCG
		}
		*/
	}
}
