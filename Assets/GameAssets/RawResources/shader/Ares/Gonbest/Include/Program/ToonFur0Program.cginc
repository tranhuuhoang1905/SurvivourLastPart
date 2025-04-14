/*
1.卡通加毛皮渲染的一个版本。 2019-09-27完成历史任务
_Color ("Main Color", Color) = (1, 1, 1, 1)		
_ColorMultiplier("Color Multipler",range(0,2)) = 1
_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
_MainTex("Albedo", 2D) = "white" {}
_Smoothness("Smoothness(光滑度MaskTex的R通道)",range(0,1)) = 1
_ShadowMask("ShadowMask(MaskTex的G通道)",range(0,1)) = 1		
_SpecStrength("SpecStrength(高光强度 MaskTex的B通道)",range(0,1)) = 0.2
_MaskTex ("MaskTex(R:光滑度，G：阴影效果，B：高光强度)", 2D) = "white" {}		
_MainShadowStrength("MainShadowStrength(主阴影强度)",range(0,1)) = 1
_MainShadowColor("MainShadowColor(主阴影颜色)",Color) = (0.9,0.76,0.8,1)		        
_SubShadowStrength("SubShadowStrength(次阴影强度)",range(0,1)) = 1
_SubShadowColor("SubShadowColor(次阴影颜色)",Color) = (0.9,0.76,0.8,1)
_ShadowBlendParam("ShadowBlendParam(0：第二阴影色,0.5：两个阴影色对半,1：第一阴影色)",range(0,1)) = 0.5        
_ShadowAreaParam("ShadowAreaParam(光暗过度)",range(0,1)) = 0.5
_SpecPowerValue("SpecPowerValue",float) = 10
_SpecularColor("SpecularColor",Color) = (1,1,1,1)
_RimRampThreshold("RimRampThreshold",Range(0,1)) = 1
_RimRampSmooth("RimRampSmooth",Range(0,1)) = 0
_RimPower("RimPower",Range(0,2)) = 1
_RimColor("RimColor",Color) = (1,1,1,1)
*/

        #include "../Include/Base/MathCG.cginc"
		#include "../Include/Base/RampCG.cginc"
        #include "../Include/Indirect/RimLightCG.cginc"
        #include "../Include/Indirect/Lightmap&SHLightCG.cginc"
        #include "../Include/Shadow/ShadowCG.cginc"
        #include "../Include/Utility/ToonUtilsCG.cginc"
        #include "../Include/Utility/FurUtilsCG.cginc"

		struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;								
            float3 wpos:TEXCOORD1;
            float4 color:TEXCOORD2;
            float3 normal:TEXCOORD3;
            float3 diff:TEXCOORD4;
            float4 screenPos:TEXCOORD5;
            GONBEST_SH_COORDS(6)
            GONBEST_SHADOW_COORDS(7)
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _MaskTex;
        uniform float _DitherAlpha;	
        uniform float _UsingDitherAlpha;        
        uniform float4 _Color ;
        uniform float _ColorMultiplier;
        uniform float3 _MainShadowColor ;
        uniform float _MainShadowStrength;
        uniform float _ShadowAreaParam ;
        uniform float3 _SpecularColor ;			
        uniform float _ShadowBlendParam ;
        uniform float3 _SubShadowColor; 
        uniform float _SubShadowStrength;
        uniform float _SpecPowerValue;
        uniform float _SpecStrength;       
        uniform float _ShadowMask;
        uniform float _Smoothness;
        uniform float _RimPower;
        uniform float4 _RimColor;
        //uniform float4 _RimDir;
        
        v2f vert (appdata_full v)
        {
            v2f o;
            float4 vpos = v.vertex;
            GONBEST_FUR_VERTEX_EXPAND(vpos,GBNormalizeSafe(v.normal),FURSTEP * v.color.r);
            GONBEST_FUR_VERTEX_FORCE(vpos,FURSTEP);
            float4 wpos = mul(unity_ObjectToWorld,vpos);
            o.wpos = wpos.xyz/wpos.w;
            o.pos = mul(UNITY_MATRIX_VP,wpos);
            o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
            o.color = v.color;
            o.normal = GBNormalizeSafe(mul(v.normal.xyz,(float3x3)unity_WorldToObject));
            o.diff = saturate(dot(o.normal,_WorldSpaceLightPos0.xyz)*0.5+0.5);
            float4 pos = o.pos;
            pos.y = pos.y * _ProjectionParams.x;
            pos.xy = (pos.xy + float2(pos.w,pos.w)) * 0.5;
            o.screenPos.xyz = pos.xyz;
            o.screenPos.w = _DitherAlpha;
            GONBEST_TRANSFER_SH(o,o.normal,wpos);
            //阴影处理
			GONBEST_TRANSFER_SHADOW_WPOS(o,wpos,v.texcoord1);					
            return o;
        }        

        fixed4 frag (v2f i) : SV_Target
        {
            float3 P = i.wpos.xyz;
            float3 L = GBNormalizeSafe(_WorldSpaceLightPos0.xyz);
            float3 V = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - P);
            float3 H = GBNormalizeSafe(L+V);
            float3 N = GBNormalizeSafe(i.normal);
            float3 RimV = GBNormalizeSafe(_WorldSpaceCameraPos.xyz - P);
            float3 RimNoL = saturate(dot(N,GBNormalizeSafe(-L)));          
            float NoL = saturate(dot(N,L));
            float RimNoV = saturate(dot(N,RimV));
            float NoH = saturate(dot(N,H)); 
            float3 diff = NoL * 0.5 + 0.5;            
            float3 lightColor = tex2D(_MaskTex, i.uv).xyz;
            float3 mainColor = tex2D(_MainTex, i.uv).xyz;

            //灯光mask		
            float specStrength = lightColor.x *_SpecStrength; 
            float lightMask = lightColor.y *_ShadowMask;
            float routhness = lightColor.z *_Smoothness;

            //引用中第一和第二阴影的差值参数
            float shadowFactor =  step(1,FloorStep(diff, 0.5, lightMask, _ShadowBlendParam));//RampTwoStep(diff,lightMask,_ShadowBlendParam);//

            float3 firstShadowColor = mainColor.xyz * _MainShadowColor.xyz * _MainShadowStrength;	
            float3 secondShadowColor = mainColor.xyz * _SubShadowColor.xyz * _SubShadowStrength;	            

            //这里对于以0.5为分割线，对斜率做了修改
            float newlightmask = lerp(lightMask * 1.2 - 0.1, lightMask * 1.25 - 0.125,step(lightMask,0.5)) ;
            

            //float firstMainFactor = step(1, FloorStep(diff, 0.5, newlightmask , _ShadowAreaParam)) ;

            float firstMainFactor = RampTwoStep(diff, newlightmask, _ShadowAreaParam);

            float3 fColor1 = lerp(firstShadowColor, mainColor.xyz, firstMainFactor);

            float3 shadowColor = lerp(firstShadowColor,secondShadowColor,shadowFactor);
            //lightMask < 0.1 ==> shadowColor;
            float3 fColor = lerp(shadowColor, fColor1, step(0.5, lightMask));	//step(1,max(floor(lightMask +  0.90999997),0))	
            
            float spec = pow(NoH,_SpecPowerValue);

            float specFactor = max(floor(routhness + 1 - spec ),0);

            float3 specColor = specStrength * _SpecularColor.xyz;

            specColor = lerp(specColor, 0, step(1 , specFactor));

            float rt = GBRimTerm(RimNoV, RimNoL,_RimPower);
            float3 rim = rt * _RimColor.rgb * _RimColor.a ;
            GONBEST_APPLY_RAMP_RIM(rim,rt);            

            float3 indirectDiff = (float3)1;
			GONBEST_APPLY_SH_COLOR(i,N,P,indirectDiff);              
            indirectDiff = indirectDiff * mainColor.xyz * 0.1 ;

            fColor = (rim + fColor + specColor)  * _Color * _ColorMultiplier;
            //fColor *= (GONBEST_DECODE_SHADOW_VALUE(i,P));//max((GONBEST_DECODE_SHADOW_VALUE(i,P)),_MainShadowColor.xyz);
            float4 Out = float4(fColor,1);
           
            //皮毛处理
            GONBEST_FUR_APPLY_COLOR(Out,i.uv.xy,FURSTEP)
            return Out;
        }
    