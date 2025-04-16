/*===============================================================
Author:gzg
Date:2019-12-03
Desc:专门处理倒影的Pass
=================================================================*/
Shader "Gonbest/Function/ReflectionHelper"
{
    
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _OffsetVector("_OffsetVector",Vector) = (1,0,0,0)
        _NormalVector("_NormalVector",Vector) = (1,0,0,0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            Name "REFLECTION&BODY"
           
            Stencil {
                Ref 1
				Comp Equal
				Pass IncrSat
            }           
           // Blend SrcAlpha  OneMinusSrcAlpha
            //ZTest Always    
            ColorMask RGB       
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog           
            
            #include "../Include/Program/ReflectionProgram.cginc"

            ENDCG
        }

        Pass
        {
            Name "REFLECTION&PANEL"
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
                Fail Zero
                ZFail Zero
            }
            ColorMask RGB

            CGPROGRAM
           #pragma vertex vert_simple
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "UnityCG.cginc"
            #include "../Include/Program/VertProgram.cginc"           
          

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);                
                return col;
            }

            ENDCG
        }
	}
}