// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Gonbest/PBR/UnityStandardHelper"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0

        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        _ParallaxMap ("Height Map", 2D) = "black" {}

        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}

        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        _DetailMask("Detail Mask", 2D) = "white" {}

        _DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
        _DetailNormalMapScale("Scale", Float) = 1.0
        _DetailNormalMap("Normal Map", 2D) = "bump" {}




    }

    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup
    ENDCG
  
    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 150

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP            
            #pragma multi_compile _EMISSION
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT DIRLIGHTMAP_COMBINED

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        Pass
        {
            Name "FORWARD&ALPHA"
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
			Blend One OneMinusSrcAlpha,Zero OneMinusSrcAlpha	

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP
            #pragma multi_compile _ALPHAPREMULTIPLY_ON
            #pragma multi_compile _EMISSION
            #pragma multi_compile _METALLICGLOSSMAP

            #pragma skip_variants SHADOWS_SOFT DIRLIGHTMAP_COMBINED

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }

        Pass
        {
            Name "FORWARD&ALPHAFADE"
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,Zero OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP
            #pragma multi_compile _ALPHABLEND_ON
            #pragma multi_compile _EMISSION
            #pragma multi_compile _METALLICGLOSSMAP

            #pragma skip_variants SHADOWS_SOFT DIRLIGHTMAP_COMBINED

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }

        Pass
        {
            Name "FORWARD&ALPHATEST"
            Tags { "LightMode" = "ForwardBase" }
      
            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP
            #pragma multi_compile _ALPHATEST_ON
            #pragma multi_compile _EMISSION
            #pragma multi_compile _METALLICGLOSSMAP

            #pragma skip_variants SHADOWS_SOFT DIRLIGHTMAP_COMBINED

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend SrcAlpha One,Zero OneMinusSrcAlpha
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP            
            #pragma multi_compile _METALLICGLOSSMAP                                    
            #pragma skip_variants SHADOWS_SOFT

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA&ALPHA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One,Zero OneMinusSrcAlpha
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP
            #pragma multi_compile _ALPHAPREMULTIPLY_ON
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA&ALPHAFADE"
            Tags { "LightMode" = "ForwardAdd" }
            Blend SrcAlpha One,Zero OneMinusSrcAlpha
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP
            #pragma multi_compile _ALPHABLEND_ON
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA&ALPHATEST"
            Tags { "LightMode" = "ForwardAdd" }
            Blend SrcAlpha One,Zero OneMinusSrcAlpha
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _NORMALMAP
            #pragma multi_compile _ALPHATEST_ON
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Shadow rendering pass
        Pass {
            Name "SHADOWCASTER"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 2.0            
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }       

        Pass {
            Name "SHADOWCASTER&ALPHA"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _ALPHAPREMULTIPLY_ON
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }   

        Pass {
            Name "SHADOWCASTER&ALPHAFADE"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _ALPHABLEND_ON
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }   

        Pass {
            Name "SHADOWCASTER&ALPHATEST"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma multi_compile _ALPHATEST_ON
            #pragma multi_compile _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }   
    }

    FallBack "VertexLit"
    CustomEditor "StandardShaderGUI"
}
