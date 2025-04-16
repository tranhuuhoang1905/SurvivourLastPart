/*
Author:gzg
Date:2019-08-20
Desc:顶点函数的一些处理
*/

#ifndef GONBEST_VERTEXUTILS_CG_INCLUDED
#define GONBEST_VERTEXUTILS_CG_INCLUDED

#include "../Base/MathCG.cginc"

/*===============在顶点函数中执行的一些功能函数===============*/

/*获取顶点函数的参数

--输入
vertex:模型顶点信息
tangent:模型切线
normal:模型法线

---输出
pp:映射到投影空间的位置.
wp:世界位置
wn:世界法线信息
wt:世界切线信息
wb:世界次法线信息
*/
inline void GetVertexParameters(in float4 vertex, in float4 tangent, in float3 normal,out float4 pp,out float4 wp,out float3 wn,out float3 wt,out float3 wb)
{
    wp = mul(unity_ObjectToWorld,vertex);
    pp = mul(UNITY_MATRIX_VP,wp);
    wn = GBNormalizeSafe(mul(normal.xyz,(float3x3)unity_WorldToObject));
    wt = GBNormalizeSafe(mul((float3x3)unity_ObjectToWorld,tangent.xyz));
    float sign = unity_WorldTransformParams.w * tangent.w;
    wb = cross(wn,wt) * sign;
}


//转换灯光从视图坐标到世界坐标
inline void GetWorldLightFormView(in float4 viewLight,out float4 worldLight)
{
    worldLight.xyz =  mul(float4(viewLight.xyz,0),UNITY_MATRIX_V).xyz;
    worldLight.w = viewLight.w;
}

//获取MatCap的UV值
inline void GetMatCapUV(in float3 worldNormal,out float2 capUV )
{
    float3 vN = mul(UNITY_MATRIX_V,float4(worldNormal,0)).xyz;
    capUV = vN.xy * 0.5 + 0.5;
}

//投影到面板
/*
wpos:顶点的世界位置
lightDir:灯光方向
world2PanelMatrix:世界坐标系转换到Panel坐标系的矩阵 :: panel.WorldToLocalMatrix();
*/
inline float4 ProjectToPanel(in float4 wpos, in float4 wlightDir,in float4x4 world2PanelMatrix)
{
    float4 L = GBNormalizeSafe(lerp(wlightDir , wpos - wlightDir, wlightDir.w));
    float4 world2PanelRowY = world2PanelMatrix[1];
    float dv = dot(world2PanelRowY,wpos);
    float dl = dot(world2PanelRowY,L);
    if(dv > 0 && dl < 0)
    {
        return wpos+ L * (dv/-dl);
    }
    return wpos;
}

//针对顶点进行翻转,镜像处理
/*
vertex:模型顶点
n:垂直于反射平面的法向量,如果非单位向量,那么就会造成顶点拉伸
shift:针对反射后的顶点的位移
注意:使用这个函数为模型做镜像反射时,请注意标记: ZTest 和 Cull 的设置.
*/
inline float4 Mirror(in float4 vertex,in float3 n, in float3 shift )
{
    //以顶点位入射向量,n为法向量
    vertex.xyz = reflect(vertex.xyz,n);
    vertex.xyz += shift;
    return vertex;
}

/*顶点膨胀
vertex:顶点位置
normal:顶点法线
amount:膨胀的程度
大部分用在:描边,皮毛处理等
*/
inline float4 VertexExpand(in float4 vertex,in float3 normal,float amount) 
{
    vertex.xyz += normal * amount;
    return vertex;        
}

#endif //GONBEST_VERTEXUTILS_CG_INCLUDED