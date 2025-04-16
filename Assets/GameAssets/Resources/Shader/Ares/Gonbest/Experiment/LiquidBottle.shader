Shader "Custom/LiquidBottle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("MainColor",Color) = (1, 1, 1, 1)
        _TopColor("TopColor",Color) = (1, 1, 0, 1)
        _FillMaxValue("FillMaxValue",float) = 4
        _FillAmount("FillAmout",Range(0 , 1)) = 0
        _EdgeWidth("EdgeWidth",Range(0 , 1)) = 0.2

        _BottleWidth("BottleWidth",Range(0,1)) = 0.2
        _BottleColor("BottleColor",Color) = (1,1,1,1)

        _InsideColor("_InsideColor",Color) = (1, 1, 0, 1)
        _ClipMaxLength("_ClipMaxLength",float) = 4
        _ClipAmount("_ClipAmount",Range(0 , 1)) = 0
        _EdgeWidth("_EdgeWidth",Range(0 , 1)) = 0.2
        _EdgeColor("_EdgeColor",Color) = (1, 1, 0, 1)     

        _RimColor("RimColor",Color)=(1,1,1,1)
        _RimWidth("RimWidth",float)=0.2

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull OFF
            AlphaToMask on
            //ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile _GONBEST_MODEL_CLIP_ON

            #include "UnityCG.cginc"
            #include  "../Include/Utility/WidgetUtilsCG.cginc"
            #include "../Include/Base/MathCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
               
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                GONBEST_MODEL_CLIP_COORDS(2)
                float3 viewDir : COLOR;
                float3 normal : COLOR2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _MainColor;
            float _FillMaxValue;
            float _FillAmount;
            float4 _TopColor;
            //float _EdgeWidth;

            float4 _RimColor;
            float _RimWidth;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                GONBEST_TRANSFER_MODEL_CLIP_Y(v,o);
                o.normal=v.normal;
                o.viewDir=GBNormalizeSafe(ObjSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i,fixed facing : VFace) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _MainColor;
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);

                float dotProduct = 1-pow(dot(i.normal, i.viewDir),_RimWidth);
                float4 rimCol=_RimColor*smoothstep(0.5,1,dotProduct);

                /*
                fixed4 edgeVal= step(i.fillEdge,0) - step(i.fillEdge,-_EdgeWidth);
                fixed4 edgeCol= edgeVal *= _TopColor * 0.9;

                fixed4 finalVal = step(i.fillEdge,0) ;//- edgeVal;
                fixed4 finalCol = finalVal * col;
                finalCol += edgeCol + rimCol;

                fixed4 topCol= _TopColor * (edgeVal+finalVal);
                
                */
                fixed4 finalColor = rimCol;
                GONBEST_MODEL_CLIP_APPLY(i,facing,col,1,finalColor);
                // float dotVal = 1- pow(dot(i.normal, i.viewDir),0.3);
                // return float4(dotVal,dotVal,dotVal,1);
                return  finalColor;
            }
            ENDCG
        }
        /*
        Pass
        {
            //Cull Front
            Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 viewDir : COLOR;
                float3 normal :NORMAL;
            };

            float4 _BottleColor;
            float _BottleWidth;

            float4 _RimColor;
            float _RimWidth;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.xyz+=v.normal.xyz*_BottleWidth;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal=v.normal.xyz;
                o.viewDir=GBNormalizeSafe(ObjSpaceViewDir(v.vertex));

                return o;
            }

            fixed4 frag (v2f i,fixed facing : VFace) : SV_Target
            {
                // sample the texture
                fixed4 col = _BottleColor;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                float dotProduct = 1-pow(dot(i.normal, i.viewDir),_RimWidth);//1-pow(dot(i.normal, i.viewDir),_RimWidth/10);
                float4 rimCol=_RimColor*smoothstep(0.2,1,dotProduct);
              
                return rimCol;
            }
            ENDCG
        }
        */
    }
}
