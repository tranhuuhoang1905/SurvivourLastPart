/*===============================================================
Author:gzg
Date:2019-12-03
Desc:使用Stencil来处理阴影
=================================================================*/
Shader "Gonbest/Function/StencilShadowHelper"
{
	Properties
	{
		_ShadowColor ("_ShadowColor", Color) = (0,0,0,1)
        _LightDir("_LightDir",Vector) = (1,0,0,0)
        _ReceiverDir("_ReceiverDir",Vector) = (1,0,0,0)
	}

    CGINCLUDE        
        #include "../Include/Base/MathCG.cginc"

        float4 _ShadowColor;
        uniform float4x4 _World2Receiver; // transformation from 
        uniform float4 _LightDir;
        uniform float4 _ReceiverDir;

        //灯光投影
        float4 lightProject(float4 wpos,float4 lpos,float4 planedir)
        {

            //灯光位置
            float4 L = lerp(GBNormalizeSafe(lpos), GBNormalizeSafe(wpos - lpos), lpos.w);
           

            //投影面的法线信息
            float4 ReceiverN = GBNormalizeSafe(planedir);
                
            //点距离投影面的距离    
            float distanceOfVertex = dot(ReceiverN, wpos); 

            //光线与面发现的夹角的Cos值.
            float lengthOfLightDirectionInY = dot(ReceiverN, L); 
            
            
            if (distanceOfVertex > 0.0 && lengthOfLightDirectionInY < 0.0)
            {
                return  L * (distanceOfVertex / (-lengthOfLightDirectionInY));
            }
            return  float4(0.0, 0.0, 0.0, 0.0);
        }

        //使用世界矩阵
        float4 vert_matrix_world(float4 vertexPos : POSITION) : SV_POSITION
        {   
            //世界位置 
            float4 wPos = mul(unity_ObjectToWorld, vertexPos);

            float4 lp =lightProject(wPos,_LightDir,float4(_World2Receiver[1][0], _World2Receiver[1][1], _World2Receiver[1][2], _World2Receiver[1][3]));
            
            return mul(UNITY_MATRIX_VP, wPos + lp);
           
        }

        //方向是世界方向
        float4 vert_dir_world(float4 vertexPos : POSITION) : SV_POSITION
        {   
            //世界位置 
            float4 wPos = mul(unity_ObjectToWorld, vertexPos);

            float4 lp =lightProject(wPos,_LightDir,_ReceiverDir);

            return mul(UNITY_MATRIX_VP, wPos + lp);
           
        }

        //参数是相对模型的方向
        float4 vert_dir_obj(float4 vertexPos : POSITION) : SV_POSITION
        {   
            //世界位置 
            float4 wPos = mul(unity_ObjectToWorld, vertexPos);

            float4 wl = mul(unity_ObjectToWorld, _LightDir);

            float4 wr = mul(unity_ObjectToWorld, _ReceiverDir);

            float4 lp = lightProject(wPos,wl,wr);

            return mul(UNITY_MATRIX_VP, wPos + lp);
           
        }

        float4 frag(void) : COLOR 
        {
            return _ShadowColor;
        }  
    ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Transparent" }

        Pass
        {
            //阴影的产生者,并且不需要接受者
            Name "SHADOWCASTER&WITHOUTRECEIVER&PLANEDIR&OBJ"
            Offset -1.0, -2.0 	
            ZWrite Off
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert_dir_obj
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog           
            ENDCG
        }

         Pass
        {//阴影的产生者
            Name "SHADOWCASTER&PLANEDIR&OBJ"
            Offset -1.0, -2.0 	
            ZWrite Off
            Stencil {
                Ref 1
				Comp Equal
				Pass IncrSat
            } 
            ColorMask RGB

            CGPROGRAM
            #pragma vertex vert_dir_obj
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog           
            ENDCG
        }

        Pass
        {
            //阴影的产生者,并且不需要接受者
            Name "SHADOWCASTER&WITHOUTRECEIVER&PLANEDIR"
            Offset -1.0, -2.0 	
            ZWrite Off
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert_dir_world
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog           
            ENDCG
        }

         Pass
        {//阴影的产生者
            Name "SHADOWCASTER&PLANEDIR"
            Offset -1.0, -2.0 	
            ZWrite Off
            Stencil {
                Ref 1
				Comp Equal
				Pass IncrSat               
            } 
            ColorMask RGB

            CGPROGRAM
            #pragma vertex vert_dir_world
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog           
            ENDCG
        }

        Pass
        {
            //阴影的产生者,并且不需要接受者
            Name "SHADOWCASTER&WITHOUTRECEIVER&MATRIX"
            Offset -1.0, -2.0 	            
            ZWrite Off
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert_matrix_world
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog           
            ENDCG
        }


        Pass
        {//阴影的产生者
            Name "SHADOWCASTER&MATRIX"
            Offset -1.0, -2.0 	
            ZWrite Off
            Stencil {
                Ref 1
				Comp Equal
				Pass IncrSat
            } 
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert_matrix_world
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog           
            ENDCG
        }

       

        Pass
        {
            //阴影的接受者
            Name "SHADOWRECEIVER"            
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
                Fail Zero
                ZFail Zero
            }
            ZWrite Off
            Blend Zero One
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert_simple
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "../Include/Program/VertProgram.cginc"

            float4 frag (v2f i) : SV_Target
            {
                return float4(0,0,0,0);
            }

            ENDCG
        }
	}
}