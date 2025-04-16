/*
Author:gzg
Date:2019-08-20
Desc:描边的顶点和片元程序
*/

#include "../Include/Base/MathCG.cginc"
#include "../Include/Utility/FogUtilsCG.cginc"
#include "../Include/Utility/VertexUtilsCG.cginc"

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;
//描边的宽度
uniform float _Outline;
//描边的颜色
uniform fixed4 _OutlineColor;
//使模型偏移,让描边永远在魔心跟后面
uniform float _OutlineOffsetZ;

//顶点结构
struct v2f_outline
{
    float4 pos:SV_POSITION; 
    float2 uv:TEXCOORD0;               
    GONBEST_FOG_COORDS(1)
};

//在模型空间进行扩展顶点
v2f_outline vert_outline_model(appdata_full v)
{
    v2f_outline o ;                
    v.vertex = VertexExpand(v.vertex,GBNormalizeSafe(v.normal), _Outline * v.color.r);    
    float4 wpos = mul(unity_ObjectToWorld,v.vertex);
    o.pos = mul(UNITY_MATRIX_VP,wpos);
    o.uv = v.texcoord.xy;
    float4 cviewpos = mul(UNITY_MATRIX_VP, float4(_WorldSpaceCameraPos.xyz, 1));                
    #if defined(UNITY_REVERSED_Z)
        //(DX)
        _OutlineOffsetZ = _OutlineOffsetZ * -0.01;
    #else
        //OpenGL
        _OutlineOffsetZ = _OutlineOffsetZ * 0.01;
    #endif
    o.pos.z = o.pos.z + _OutlineOffsetZ * cviewpos.z ;
    GONBEST_TRANSFER_FOG(o, o.pos, wpos);
    return o;
}

//在裁剪空间进行扩展顶点
v2f_outline vert_outline_clip(appdata_full v)
{
    v2f_outline o ;                
    //将顶点转到裁剪空间
    float4 wpos = mul(unity_ObjectToWorld,v.vertex);
    o.pos = mul(UNITY_MATRIX_VP,wpos);
    o.uv = v.texcoord.xy;
    //将法线转到相机空间
    float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);
    //裁剪空间计算法线的值
    normal.x *= UNITY_MATRIX_P[0][0];
    normal.y *= UNITY_MATRIX_P[1][1];
    //根据法线和描边大小缩放模型
    o.pos.xy += _Outline * normal.xy * v.color.r;
    float4 cviewpos = mul(UNITY_MATRIX_VP, float4(_WorldSpaceCameraPos.xyz, 1));                
    #if defined(UNITY_REVERSED_Z)
        //(DX)
        _OutlineOffsetZ = _OutlineOffsetZ * -0.01;
    #else
        //OpenGL
        _OutlineOffsetZ = _OutlineOffsetZ * 0.01;
    #endif
    o.pos.z = o.pos.z + _OutlineOffsetZ * cviewpos.z ;
    GONBEST_TRANSFER_FOG(o, o.pos, wpos);
    return o;
}

//根据颜色进行描边
fixed4 frag_outline(v2f_outline i) :COLOR
{

    fixed4 color = tex2D(_MainTex,i.uv)*_OutlineColor;                
    GONBEST_APPLY_FOG(i, color)
    return color;
}