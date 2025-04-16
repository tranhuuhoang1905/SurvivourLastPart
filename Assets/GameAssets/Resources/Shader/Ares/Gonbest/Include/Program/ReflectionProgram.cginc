/*
Author:gzg
Date:2019-08-20
Desc:倒影反射 用的顶点和片元程序
*/

    #include "../Include/Utility/FogUtilsCG.cginc"
    #include "../Include/Utility/VertexUtilsCG.cginc"
    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float4 normal: NORMAL;
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;    
        GONBEST_FOG_COORDS(2)    
        
    };

    sampler2D _MainTex;
    float4 _MainTex_ST;
    float3 _OffsetVector;
    float3 _NormalVector;

    v2f vert (appdata v)
    {
        v2f o;                  
        v.vertex = Mirror(v.vertex,_NormalVector,_OffsetVector);
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv.xy;
        GONBEST_TRANSFER_FOG(o, o.vertex, mul(unity_ObjectToWorld,v.vertex).xyz);
        return o;
    }

    fixed4 frag (v2f i) : SV_Target
    {
        // sample the texture
        fixed4 col = tex2D(_MainTex, i.uv);
        // apply fog
        GONBEST_APPLY_FOG(i, col);    
        return col;
    }