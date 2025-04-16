/*===============================================================
Author:gzg
Date:2019-12-03
Desc:溶解处理的渲染Pass组
=================================================================*/
Shader "Gonbest/Function/DissolveHelper"
{
	Properties
	{
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _MaskTex ("_MaskTex (R)", 2D) = "white" {}
        _GrayFactor("_GrayFactor",float) = 0
        _GrayTime("_GrayTime",float) = 0.01  
        _DissTime("_DissTime",float) = 0.01  
        _Timeline("_Timeline",float) = 0.01  

	}
    SubShader
    {
        Pass
		{//一个消融的Shader		
			Name "DISSOLVE&GRAY"
			Cull Back
			ColorMask RGB
			CGPROGRAM
			#pragma vertex vert_simple
			#pragma fragment fragWithGray
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "UnityCG.cginc"
            #include "../Include/Program/VertProgram.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;			
			uniform float _GrayTime;
			uniform float _DissTime;
			uniform float _Timeline;

			fixed4 fragWithGray( v2f i ) : COLOR
			{
				fixed4 mainTex = tex2D( _MainTex, i.uv );
				clip( mainTex.a - 0.1f );
				fixed4 color = 0;
				color.a = mainTex.a;
				fixed3 gray = dot( mainTex.rgb, fixed3( 0.222f, 0.707f, 0.071f ) );
				if ( _Timeline <= _GrayTime ) {
					float r = _Timeline / _GrayTime;
					color.rgb = mainTex.rgb * ( 1.0f - r ) + gray * r;
				} else {
					color.rgb = gray;
					float r = ( _Timeline - _GrayTime ) / _DissTime;
					fixed cut = gray.r - r;
					fixed st = step(0,cut);
					color.rgb = st * gray + fixed3(1-st,1-st,1-st) ;					
					clip( cut+0.02 );				
				}
				return float4(color.xyz,0);
			}
			ENDCG
		}		

        Pass
		{
            Name "DISSOLVE&MASK"
			ZWrite Off			
			CGPROGRAM			
			#pragma vertex vert_simple
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "UnityCG.cginc"
            #include "../Include/Program/VertProgram.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform sampler2D _MaskTex;
            //灰色化的程度
			uniform float _GrayFactor;

			fixed4 frag(v2f vf):COLOR
			{					
				fixed4 mainTex = tex2D(_MainTex,vf.uv);								
				float4 maskTex = tex2D(_MaskTex,vf.uv);
			    float coef = step(0, maskTex.r - _GrayFactor + 0.0001);
				fixed grey = dot(mainTex.rgb, fixed3(0.299, 0.587, 0.114)); 
				mainTex.rgb = lerp( (fixed3)grey,mainTex.rgb ,coef);
				return  float4(mainTex.rgb,0);
			}
			ENDCG
		}	
    }
}