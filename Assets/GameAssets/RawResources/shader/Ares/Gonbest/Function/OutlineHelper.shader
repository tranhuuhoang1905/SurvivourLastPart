
/*===============================================================
Author:gzg
Date:2019-12-03
Desc:描边渲染的Pass
=================================================================*/
Shader "Gonbest/Function/OutlineHelper"
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
        _Outline("OutLine Width",float) = 0.002    
        _OutlineColor("Outline Color",Color) = (0,0,0,0)
        _OutlineOffsetZ("Outline Offset Z",float) = 0
	}
    SubShader
    {
        Pass
		{//这个是为了画外围线--只围着模型四周划线
			Name "OUTLINE&MODEL"
			Cull Front
			ZWrite Off
			Offset 1, 1
			ColorMask RGB
			CGPROGRAM
                #pragma vertex vert_outline_model
                #pragma fragment frag_outline
                #pragma multi_compile_fog	
                #include "../Include/Program/OutlineProgram.cginc"			
			ENDCG
		}

        Pass
		{//这个是为了画外围线--只围着模型四周划线
			Name "OUTLINE&CLIP"
			Cull Front
			ZWrite Off
			Offset 1, 1
			ColorMask RGB
			CGPROGRAM
                #pragma vertex vert_outline_clip
                #pragma fragment frag_outline
                #pragma multi_compile_fog	
                #include "../Include/Program/OutlineProgram.cginc"			
			ENDCG
		}

		 Pass
		{//这个是为了画外围线--只围着模型四周划线
			Name "EDGELINE&MODEL"
			Cull Front
			ZWrite On
			Offset 1, 1
			ColorMask RGB
			CGPROGRAM
                #pragma vertex vert_outline_model
                #pragma fragment frag_outline
                #pragma multi_compile_fog	
                #include "../Include/Program/OutlineProgram.cginc"			
			ENDCG
		}

        Pass
		{//这个是为了画外围线--只围着模型四周划线
			Name "EDGELINE&CLIP"
			Cull Front
			ZWrite On
			Offset 1, 1
			ColorMask RGB
			CGPROGRAM
                #pragma vertex vert_outline_clip
                #pragma fragment frag_outline
                #pragma multi_compile_fog	
                #include "../Include/Program/OutlineProgram.cginc"			
			ENDCG
		}
    }
}