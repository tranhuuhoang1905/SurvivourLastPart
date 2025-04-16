/*
Author:gzg
Date:2019-08-20
Desc:皮毛的一些宏处理
*/

#ifndef GONBEST_FURUTILS_CG_INCLUDED
#define GONBEST_FURUTILS_CG_INCLUDED

/*皮毛的一些处理方法*/
#if defined(_GONBEST_FUR_ON)
    //形成皮毛的纹理
    sampler2D _FurNoiseTex;    
    //皮毛长度
    float _FurLength;
    //厚薄
    float _FurThinness;
    //密度
    float _FurDensity;

    //顶点沿着法线位移
    #define GONBEST_FUR_VERTEX_EXPAND(vertex,normal,step) vertex.xyz = vertex.xyz + normal * _FurLength * step;

    //应用皮毛
    #define GONBEST_FUR_APPLY_COLOR(color,nuv,step) \
                fixed3 noise = tex2D(_FurNoiseTex, nuv * _FurThinness).r;\
                color.a = clamp(noise - (step * step) * _FurDensity, 0, 1);


    #if defined(_GONBEST_FUR_FORCE_ON)
        //全局力的方向
        float4 _ForceGlobal;
        //本地力的方向(模型)
        float4 _ForceLocal;
        #define GONBEST_FUR_VERTEX_FORCE(vertex,step) vertex.xyz += clamp(mul(unity_WorldToObject, _ForceGlobal).xyz + _ForceLocal.xyz, -1, 1) * pow(step, 3) * _FurLength;
    #else
        #define GONBEST_FUR_VERTEX_FORCE(vertex,step)
    #endif

    #if defined(_GONBEST_FUR_SHADE_ON)
        //皮毛阴影处理
        float _FurShading;

        #define GONBEST_FUR_APPLY_SHADING(color,step) color.rgb -= (pow(1 - step, 3)) * _FurShading;
    #else
        #define GONBEST_FUR_APPLY_SHADING(color,step)
    #endif    
    
#else
    #define GONBEST_FUR_VERTEX_EXPAND(vertex,normal,step)
    #define GONBEST_FUR_APPLY_COLOR(color,nuv,step)
    #define GONBEST_FUR_VERTEX_FORCE(vertex,step)
    #define GONBEST_FUR_APPLY_SHADING(color,step)
#endif

#endif//GONBEST_FURUTILS_CG_INCLUDED
