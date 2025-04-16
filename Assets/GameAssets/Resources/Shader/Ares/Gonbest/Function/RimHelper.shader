/*===============================================================
Author:gzg
Date:2019-12-03
Desc:边缘光渲染的处理
=================================================================*/
Shader "Gonbest/Function/RimHelper"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)		
		_ColorMultiplier("Color Multipler",range(0,2)) = 1
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_BumpMap("Normal Map",2D) = "black"{}
		_BumpScale("Normal Map Scale",Range(0,2)) = 1  //发现比率			        
        _RimColor("RimColor",Color) = ( 1, 1, 1, 1 )
		_RimMultiplier("RimMultiplier",range(0,5)) = 1
		_RimPower("RimPower",float) = 1 
        _InnerColor("RimColor2",Color) = (0,0,0,0)
        _InnerColorPower("RimColor2Power",float) = 10
		_FlowPower("FlowPower",float) = 3  
		_FlowFreq("FlowFreq",float) = 3 
		_FlashFreq("FlashFreq",float) = 0 
		_ViewFixedDir("ViewFixedParam",Vector) = (0,0,0,0)
		_ISUI("IsUI",float) = 0  
	}

	CGINCLUDE
		#include "../Include/Base/MathCG.cginc"
		#include "../Include/Utility/FogUtilsCG.cginc"
		#include "../Include/Utility/WidgetUtilsCG.cginc"
		#include "../Include/Utility/VertexUtilsCG.cginc"
		#include "../Include/Utility/PixelUtilsCG.cginc"

		//调制的颜色定义
		uniform fixed4 _Color = fixed4(1,1,1,1);
		//调制的乘积参数
		uniform fixed _ColorMultiplier = 1;	
		uniform sampler2D _MainTex;
		uniform half4 _MainTex_ST;
		uniform sampler2D _BumpMap;					
		uniform float _BumpScale;
		uniform fixed4 _RimColor = fixed4( 1, 1, 1, 1 );
		uniform float _RimPower = 0.01;		
		uniform float _RimMultiplier =1;		
		uniform float _FlowPower;
        uniform float _FlowFreq ;
		uniform float _FlashFreq;
		uniform fixed4 _InnerColor = fixed4( 0, 0, 0, 0 );
		uniform float _InnerColorPower = 10;
		uniform float _ISUI = 0;
					

		struct v2f {
			float4 pos : POSITION;				      	
			half2 uv :TEXCOORD0;		      
			float4 wnOrnv :TEXCOORD1;
			float4 wb :TEXCOORD2;
			float4 wt : TEXCOORD3;
			GONBEST_VIEW_FIXED_COORDS(4)							
			GONBEST_FOG_COORDS(5)
		};

		v2f vert( appdata_base v ) 
		{
			v2f o = ( v2f )0;		      
			o.pos = UnityObjectToClipPos( v.vertex );
			float4 wpos = mul(unity_ObjectToWorld,v.vertex);
			float3 viewDir = GBNormalizeSafe(ObjSpaceViewDir(v.vertex));
			o.uv = TRANSFORM_TEX( v.texcoord, _MainTex );
			float3 nl= GBNormalizeSafe(v.normal);	
			GONBEST_TRANSFER_VIEW_FIXED(o)
			GONBEST_VIEW_FIXED_APPLY(o,viewDir)
			o.wnOrnv.w = dot(viewDir,nl);
			GONBEST_TRANSFER_FOG(o, o.pos,wpos);
			return o;
		}
	
		v2f vert_tn( appdata_full v ) 
		{
			v2f o =(v2f)0;			
			float4 ppos,wpos;
			float3 wt,wn,wb;    
			GetVertexParameters(v.vertex, v.tangent, v.normal, ppos, wpos, wn, wt, wb);
			o.pos = ppos;
			o.wt = float4(wt,wpos.x);        
			o.wb = float4(wb,wpos.y);
			o.wnOrnv = float4(wn,wpos.z);
			o.uv = TRANSFORM_TEX( v.texcoord, _MainTex );	
			GONBEST_TRANSFER_VIEW_FIXED(o)		
			GONBEST_TRANSFER_FOG(o, o.pos,wpos);
			return o;
		}

		fixed4 frag( v2f i ) : COLOR 
		{	    	          
			float3 WN = GBNormalizeSafe(i.wnOrnv.xyz);
			float3 P = float3(i.wt.w, i.wb.w, i.wnOrnv.w);
 			float3 V  = GetWorldViewDirWithUI(P,_ISUI);
			GONBEST_VIEW_FIXED_APPLY(i,V)
   			//NoV
            float NoV= dot(V, WN);
			float rim = 1-NoV;
			fixed3 diffuse = _RimColor.rgb * pow(rim,_RimPower);
			float4 temp = GONBEST_TEX_SAMPLE(_MainTex,i.uv); 		
			fixed3 color = temp.rgb  + diffuse * _RimMultiplier ;		  
			GONBEST_APPLY_FOG(i, color);					
			return fixed4( color , 1.0 );
		}

		fixed4 frag_tn( v2f i ) : COLOR 
		{	    	          
			//处理法线
			float4 NT = tex2D(_BumpMap,i.uv.xy);
			float3 N = GetWorldNormalFromBump(NT,_BumpScale,GBNormalizeSafe(i.wt.xyz),GBNormalizeSafe(i.wb.xyz),GBNormalizeSafe(i.wnOrnv.xyz));			
			float3 P = float3(i.wt.w, i.wb.w, i.wnOrnv.w);
 			float3 V  = GetWorldViewDirWithUI(P,_ISUI);
			GONBEST_VIEW_FIXED_APPLY(i,V)
   			//NoV
            float NoV= dot(V, N);

            float oneMinusNoV = pow(1-abs(NoV),_RimPower);

			//读取颜色强度和alpha通道
			float2 mclr = tex2D(_MainTex, i.uv).xz;
			
			//颜色处理
			float emission = mclr.x * _ColorMultiplier;                
			float rimValue = saturate(emission + oneMinusNoV) * _RimMultiplier; 
			//读取流光
			float flow = tex2D(_MainTex, (_Time.xx * _FlowFreq) + i.uv).y;
			emission *= (flow * _FlowPower);  

			//边缘颜色
			float3 startColor = rimValue * _RimColor.xyz;         
			float3 overColor = _InnerColor.xyz * rimValue - startColor ;
			float3 rimColor = (sin(_Time.x * _FlashFreq) * overColor + startColor) * _Color.xyz;

			//透明
			float alpha = rimValue * mclr.y * _Color.w;
            float4 fColor = float4((1 + emission) * rimColor, alpha);
			return fColor;
		}

	ENDCG

    SubShader
    {
		Pass
		{	
			//边缘光的Pass
			Name "RIMLIGHT&SIMPLE"					
			Cull Back
			ColorMask RGB
			CGPROGRAM
				#pragma vertex vert_tn
				#pragma fragment frag
				//#pragma fragmentoption ARB_precision_hint_fastest	
				#pragma multi_compile _GONBEST_USE_FIXED_VIEW_ON				
				#pragma multi_compile_fog
			ENDCG
		}

        Pass
		{	
			//边缘光的Pass
			Name "RIMLIGHT"					
			Cull Back
			ColorMask RGB
			CGPROGRAM
				#pragma vertex vert_tn
				#pragma fragment frag
				//#pragma fragmentoption ARB_precision_hint_fastest	
				#pragma multi_compile _GONBEST_USE_FIXED_VIEW_ON				
				#pragma multi_compile_fog
			ENDCG
		}

		Pass
		{	
			//带有Alpha的的边缘光
			Name "RIMLIGHT&ALPHA"					
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert_tn
				#pragma fragment frag_tn
				//#pragma fragmentoption ARB_precision_hint_fastest	
				#pragma multi_compile _GONBEST_USE_FIXED_VIEW_ON					
				#pragma multi_compile_fog
			ENDCG
		}
    }
}