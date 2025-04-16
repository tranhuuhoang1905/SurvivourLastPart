/*
Author:gzg
Date:2019-08-20
Desc:毛发的顶点和片元处理程序
*/

#include "../Include/Base/MathCG.cginc"
#include "../Include/Base/EnergyCG.cginc"
#include "../Include/Base/NormalCG.cginc"		
#include "../Include/Base/FresnelCG.cginc"		
#include "../Include/Specular/SmithSchlickCG.cginc"	
#include "../Include/Specular/BeckmannCG.cginc"	
#include "../Include/Specular/GGXCG.cginc"
#include "../Include/Indirect/IndirectSpecularCG.cginc"
#include "../Include/Indirect/EnvBRDFCG.cginc"
#include "../Include/Utility/VertexUtilsCG.cginc"
#include "../Include/Utility/FogUtilsCG.cginc"		
#include "../Include/Utility/FlowUtilsCG.cginc"		
#include "../Include/Utility/WidgetUtilsCG.cginc"
#include "../Include/Utility/PixelUtilsCG.cginc"
#include "../Include/Utility/FurUtilsCG.cginc"

uniform sampler2D _MainTex;				
uniform float4 _MainTex_ST;
uniform sampler2D _MetallicTex;
uniform sampler2D _BumpMap;			
uniform sampler2D _MaskTex;
uniform float4 _EnvCube_HDR;
UNITY_DECLARE_TEXCUBE(_EnvCube);
uniform float _Glossiness;
uniform float _Metallic;		
uniform float _BumpScale;
uniform float3 _DiffuseColor;				
uniform float _SpecPower;
uniform float _EnvDiffPower;
uniform float _EnvSpecPower;
uniform float _OA;
uniform float4 _MainLightPos;
uniform float3 _MainLightColor;
uniform float4 _FillInLightPos;
uniform float3 _FillInLightColor;
uniform float4 _LogicColor;
uniform float _ISUI;

    
struct v2f_base
{
    float4 pos	: SV_POSITION;
    float4 uv	: TEXCOORD0;
    float4 _wt 			: TEXCOORD1;
    float4 _wb 			: TEXCOORD2;
    float4 _wn 			: TEXCOORD3;
    float4 _fl			: TEXCOORD4;
    float4 _ml   		: TEXCOORD5;
    GONBEST_FOG_COORDS(6)	
};

v2f_base vert_base(appdata_full v)
{
    v2f_base o =(v2f_base)0;	
    float4 vpos = v.vertex;
    GONBEST_FUR_VERTEX_EXPAND(vpos,GBNormalizeSafe(v.normal),FURSTEP * v.color.r);
    GONBEST_FUR_VERTEX_FORCE(vpos,FURSTEP);

    float4 ppos,wpos;
    float3 wt,wn,wb;    
    GetVertexParameters(vpos, v.tangent, v.normal, ppos, wpos, wn, wt, wb);
    o.pos = ppos;
    o._wt = float4(wt,wpos.x);        
    o._wb = float4(wb,wpos.y);
    o._wn = float4(wn,wpos.z);								

    float4 fl;
    GetWorldLightFormView(_FillInLightPos,fl);
    o._fl = fl;
    float4 ml;
    GetWorldLightFormView(_MainLightPos,ml);
    o._ml = ml;

    //纹理坐标	
    o.uv.xy = TRANSFORM_TEX( v.texcoord, _MainTex );
    o.uv.zw = GONBEST_CALC_FLOW_UV(v, GONBEST_USE_FLOW_UV(v.texcoord,v.texcoord1));		
    //获取雾的采样点			
    GONBEST_TRANSFER_FOG(o, o.pos, wpos);	
    return o;
}

fixed4 frag_base(v2f_base i) :COLOR
{
    float4 color = tex2D(_MainTex,i.uv.xy);// FUNCELL_TEX_SAMPLE(_MainTex,i.uv) ;
    float4 maskColor = tex2D(_MaskTex,i.uv.xy);
    color = lerp(color,_LogicColor,maskColor.b);
    
    //处理颜色值
    GONBEST_APPLY_COLOR_MULTIPLIER(color)

    //应用AlphaTest
    GONBEST_APPLY_ALPHATEST(color)
    
    GONBEST_FUR_APPLY_SHADING(color,FURSTEP);
    //自发光
    float3 emissive = _DiffuseColor * color;	

    //处理粗糙度和金属度
    float4 metaColor = tex2D(_MetallicTex,i.uv);
    float smoothness = _Glossiness * metaColor.g;
    float perceptualRoughness = max(0.08, 1 - smoothness);
    float rough = perceptualRoughness * perceptualRoughness;
    float meta = _Metallic * metaColor.r;
    float skin = metaColor.b;
    //处理高亮值
    float specPowner = _SpecPower * GONBEST_INV_PI;

    //根据能量守恒获取基础的散射光和高亮光颜色
    half oneMinusReflectivity;
    float3 diffColor,specularColor;
    GetDiffuseAndSpecular(color, meta, diffColor, specularColor, oneMinusReflectivity);

    //处理法线
    float4 NT = tex2D(_BumpMap,i.uv.xy);
    float3 TN = GBUnpackScaleNormal(NT,_BumpScale);
    float3 N = GBNormalizeSafe(float3(GBNormalizeSafe(i._wt.xyz) * TN.x + GBNormalizeSafe(i._wb.xyz) * TN.y + GBNormalizeSafe(i._wn.xyz) * TN.z));			
    float3 P = float3(i._wt.w, i._wb.w, i._wn.w);			
    
    //视线
    float3 V = GetWorldViewDirWithUI(P.xyz, _ISUI);
    float3 R = reflect(-V,N);

    //主光
    float3 L = GBNormalizeSafe(i._ml.xyz);
    float3 H = GBNormalizeSafe(L+V);	
    float NoL = saturate(dot(N,L));
    float NoV = saturate(dot(N,V));
    float NoH = saturate(dot(N,H));
    float VoH = saturate(dot(V,H));

    //次光
    float3 L2 = GBNormalizeSafe(i._fl.xyz);
    float3 H2 = GBNormalizeSafe(L2+V);	
    float NoL2 = saturate(dot(N,L2));
    float NoH2 = saturate(dot(N,H2));
    float VoH2 = saturate(dot(V,H2));			
    float LoH2 = saturate(dot(L,H2));
    

    //微平面阴影
    float oa = _OA * _OA - 0.5;
    float microshadow= saturate(2 * oa + abs(NoL));
    float microshadow2= saturate(2 * oa + abs(NoL2));

    //漫反射
    float3 diff = i._ml.w *  _MainLightColor.rgb * NoL;
    float3 diff2 = i._fl.w * _FillInLightColor.rgb * NoL2;

    //高光			
    float GGX = GBGGXSpecularTerm(NoH, NoL,NoV, rough);
    float3 F = GBFresnelTermFastWithSpecGreen(specularColor,VoH);			
    float3 spec = GGX * F * diff  ;

    float GGX2 = GBGGXSpecularTerm(NoH2, NoL2,NoV, rough);  						
    float3 F2 = GBFresnelTermFastWithSpecGreen(specularColor,VoH2);						
    float3 spec2 = GGX2 * F2 * diff2;
    
    //间接光
    float3 indirect = IndirectSpecular_Custom(UNITY_PASS_TEXCUBE(_EnvCube), _EnvCube_HDR,R,rough,meta) ;
    indirect *= SurfaceReductionTerm(rough,perceptualRoughness);
    indirect *= GBFresnelLerp(specularColor,GrazingTerm(smoothness,oneMinusReflectivity),NoV);
    indirect *= lerp(_EnvDiffPower,_EnvSpecPower, meta);
    
    float4 Out = (float4)0;			
    Out.rgb = (diff * microshadow  + diff2 * microshadow2) * diffColor;
    Out.rgb += (spec + spec2) *specPowner ;
    Out.rgb += indirect;
    Out.rgb += emissive;			
    Out.a = color.a;					
    Out = saturate(Out);

    //皮毛处理
    GONBEST_FUR_APPLY_COLOR(Out,i.uv.xy,FURSTEP)
    //流光
    GONBEST_APPLY_FLOW(i.uv.zw,Out,maskColor.r)	
    //颜色闪烁
    GONBEST_APPLY_FLASH(Out, maskColor.g, i.uv.xy);
    //对应模型雾的颜色
    GONBEST_APPLY_FOG(i, Out);		

    return Out;
}