/*
Author:gzg
Date:2019-08-20
Desc:一些工具函数
*/

#ifndef GONBEST_WIDGETUTILS_CG_INCLUDED
#define GONBEST_WIDGETUTILS_CG_INCLUDED
#include "../Indirect/IndirectSpecularCG.cginc"
#include "../Base/MathCG.cginc"

//根据当前渲染的面来获取最终颜色---定义了facing:VFACE中的frag中使用
#define GONBEST_GET_FINAL_COLOR(vface,backColor,frontColor) vface > 0 ? frontColor:backColor;

//对模型的颜色进行调制处理
#if defined(_GONBEST_COLOR_MULTIPLIER_ON)  
	//调制的颜色定义
	uniform fixed4 _Color = fixed4(1,1,1,1);
	//调制的乘积参数
	uniform fixed _ColorMultiplier = 1;	
	
	//1.颜色相乘放到fragment中比较准确,并且不管是哪个显卡都能显示成一样的.
	//2.如果放到vertex中,通过寄存器传递.有些显卡会把这些值调整到[0,1]区间,有些显卡不会,导致不同的机器显示的效果不同.
	#define GONBEST_APPLY_COLOR_MULTIPLIER(color)  color *= _Color * _ColorMultiplier;
#else
	#define GONBEST_APPLY_COLOR_MULTIPLIER(color)
#endif

/************************是否使用AlphaTest*******************/
#if defined(_GONBEST_ALPHA_TEST_ON)
	//AlphaTest的值 --- 这个值的类型不要优化为fixed.
	uniform float _Cutoff = 0.001;
	#define GONBEST_APPLY_ALPHATEST(color) GONBEST_APPLY_ALPHATEST_EX(color,_Cutoff)
	#define GONBEST_APPLY_ALPHATEST_VAL(val)\
				float __v4dfs = val - _Cutoff;\
				__v4dfs-=0.001;\
				clip(__v4dfs);

	#if defined(_GONBEST_ALPHA_TEST_MASK_ON)	
		uniform sampler2D _AlphaTestMaskTex;
		uniform half4 _AlphaTestMaskTex_ST;
		uniform fixed4 _AlphaTestColor;

		#define GONBEST_APPLY_ALPHATEST_EX(color,cutoff)\
				fixed cutout_mask = tex2D( _AlphaTestMaskTex, TRANSFORM_TEX( i.uv, _AlphaTestMaskTex ) ).r;\
				cutout_mask *= color.a;\
                fixed cutref = step( cutoff, ( ( _AlphaTestColor.a - 0.5f ) + cutout_mask ) );\
                clip( cutref - 0.5f );\
				color.rgb += ( ( cutref - step( cutoff, cutout_mask ) ) * _AlphaTestColor.rgb );
		
	#else
		//应用AlphaTest --- 这里强转一下float,并且在做一个+0.001的操作是防止,被优化成clip(fc.a - _Cutoff) 而clip(fc.a - _Cutoff)在某些机器比如(vivo X5M)上会没有效果not work.
		#define GONBEST_APPLY_ALPHATEST_EX(color,cutoff)\
				float __v4dfs = color.a - cutoff;\
				__v4dfs-=0.001;\
				clip(__v4dfs);

	#endif		

			
#else		
	#define GONBEST_APPLY_ALPHATEST(color) 
	#define GONBEST_APPLY_ALPHATEST_EX(color,cutoff)
	#define GONBEST_APPLY_ALPHATEST_VAL(val) 
#endif




/************************是否使用MatCap*******************/
#if defined(_GONBEST_MATCAP_ON)
	//定义光照材质捕捉的贴图
    uniform sampler2D _MatCapTex;
	
	
	//matcap的寄存器定义
	#define GONBEST_MATCAP_COORDS(idx1) half2 _matcap : TEXCOORD##idx1;
	//matcap的坐标转换 --> i:vert的输入(需要包含:normal),o:vert的输出
	#define GONBEST_TRANSFER_MATCAP(i,o) o._matcap = mul((float3x3)UNITY_MATRIX_IT_MV, i.normal).xy * 0.5 + float2(0.5,0.5);
	
	#if defined(_GONBEST_MATCAP_MIX_ON)	  //使用混合处理
		//混合值
		uniform fixed _MixValue;
		//matcap的颜色应用 --> i:frag的输入,color:颜色输入输出,
		#define GONBEST_APPLY_MATCAP(i,color) color.rgb =  color.rgb* (1-_MixValue) + tex2D(_MatCapTex,i._matcap).rgb * _MixValue;
	#else
		#define GONBEST_APPLY_MATCAP(i,color) color.rgb *= tex2D(_MatCapTex,i._matcap).rgb;
	#endif
#else   
	#define GONBEST_MATCAP_COORDS(idx1)
	#define GONBEST_TRANSFER_MATCAP(i,o)
	#define GONBEST_APPLY_MATCAP(i,color)
#endif


/************************纹理采样,是否使用ALPHA贴图*******************/
#if defined(UNITY_COMPILER_CG)
// Cg does not have tex2Dgrad and friends, but has tex2D overload that
// can take the derivatives
#define tex2Dgrad tex2D
#endif

#define GONBEST_TEX_WITH_ALPHATEX_SAMPLE(rgbtex,atex,uv) float4(tex2D(rgbtex,uv.xy).rgb,tex2D(atex,uv.xy).r)
#define GONBEST_TEX_WITH_ALPHATEX_SAMPLE_LEVEL(rgbtex,atex,uv,dx,dy) float4(tex2Dgrad(rgbtex,uv.xy,dx,dy).rgb,tex2Dgrad(atex,uv.xy,dx,dy).r)


#if defined(_GONBEST_ALPHA_TEX_ON)
	//Alpha贴图
	uniform sampler2D _AlphaTex;
	
	//采样纹理采样
	#define GONBEST_TEX_SAMPLE(tex,uv) GONBEST_TEX_WITH_ALPHATEX_SAMPLE(tex,_AlphaTex,uv)
	#define GONBEST_TEX_SAMPLE_LEVEL(tex,uv,level) GONBEST_TEX_WITH_ALPHATEX_SAMPLE_LEVEL(tex,_AlphaTex,uv,ddx(uv)*level,ddy(uv)*level)
#else
	//采样纹理采样
	#define GONBEST_TEX_SAMPLE(tex,uv) tex2D(tex,uv)
	#define GONBEST_TEX_SAMPLE_LEVEL(tex,uv,level) tex2Dgrad(tex,uv,ddx(uv)*level,ddy(uv)*level)
#endif

//针对第二张纹理的采样,是否滴啊有Alpha通道
#if defined(_GONBEST_TWO_ALPHA_TEX_ON)
	//Alpha贴图
	uniform sampler2D _AlphaTex2;
	
	//采样纹理采样
	#define GONBEST_TWO_TEX_SAMPLE(tex,uv) GONBEST_TEX_WITH_ALPHATEX_SAMPLE(tex,_AlphaTex2,uv)

#else
	//采样纹理采样
	#define GONBEST_TWO_TEX_SAMPLE(tex,uv) tex2D(tex,uv)
#endif


/************************使用Cube来进行采样*******************/
#if defined(_GONBEST_ENV_CUBE_ON)	
	//环境的CUBE
	uniform half _EnvCubeMixer;
	uniform float4 _EnvCube_HDR;
	UNITY_DECLARE_TEXCUBE(_EnvCube);
	

	#define GONBEST_CUBE_COORDS(idx1)	half3 _reflectedDir:TEXCOORD##idx1;
	#define GONBEST_TRANSFER_CUBE(o, wnormal, wpos) \
					float3 world_view = GBNormalizeSafe(_WorldSpaceCameraPos - wpos.xyz);\
					o._reflectedDir = reflect(world_view,wnormal).xyz;

	#define GONBEST_CUBE_APPLY(i,color) color.rgb += GONBEST_INDIRECT_SPECULAR(_EnvCube, _EnvCube_HDR, i._reflectedDir , 0, 1) *_EnvCubeMixer;// lerp(color, GONBEST_INDIRECT_SPECULAR(_EnvCube, _EnvCube_HDR, i._reflectedDir , 0, 1),_EnvCubeMixer);
#else
	#define GONBEST_CUBE_COORDS(idx1)
	#define GONBEST_TRANSFER_CUBE(o, wnormal, wpos)
	#define GONBEST_CUBE_APPLY(i,color)
#endif	

/************************对颜色的透明度进行预先处理*******************/
#if defined(_GONBEST_PROCESS_A_OF_COLOR)
	#define GONBEST_PROCESS_ALPHA_OF_COLOR(color,a) color.xyz *= a;
#else
	#define GONBEST_PROCESS_ALPHA_OF_COLOR(color,a)
#endif


/**************使用Mask贴图************************/
#if defined(_GONBEST_MASK_ON)
	//Mask贴图
	uniform sampler2D _MaskTex;
		
	#if defined(_GONBEST_MASK_ST_ON)  //使用Mask的偏移Offset和重复Tile
		//MaskTex的ST
		uniform half4 _MaskTex_ST;
		//定义Mask坐标
		#define GONBEST_MASK_COORDS(idx1) half2 _muv : TEXCOORD##idx1;
		#if defined(_GONBEST_MASK_TEXCOORD_2_ON)
			//Mask坐标转移 -- 输入使用纹理坐标texcoord1
			#define GONBEST_TRANSFER_MASK(i,o) o._muv = TRANSFORM_TEX(i.texcoord1, _MaskTex);
		#else
			//Mask坐标转移 -- 输入使用纹理坐标texcoord
			#define GONBEST_TRANSFER_MASK(i,o) o._muv = TRANSFORM_TEX(i.texcoord, _MaskTex);
		#endif
		//采样掩码
		#define GONBEST_SAMPLE_MASK(i) fixed4 __maskColor = tex2D(_MaskTex,i._muv);	
		//应用Mask的颜色处理
		#define GONBEST_APPLY_MASK(i,color) color *= tex2D(_MaskTex,i._muv);
	#else
		//定义Mask坐标
		#define GONBEST_MASK_COORDS(idx1)
		//Mask坐标转移
		#define GONBEST_TRANSFER_MASK(i,o)
		//采样掩码
		#define GONBEST_SAMPLE_MASK(i) fixed4 __maskColor = tex2D(_MaskTex,i.uv.xy);	
		//应用Mask的颜色处理
		#define GONBEST_APPLY_MASK(i,color) color *= tex2D(_MaskTex,i.uv.xy);
	#endif
	
	//掩码的第一个值
	#define GONBEST_MASK_VALUE_1 __maskColor.x
	//掩码的第二个值
	#define GONBEST_MASK_VALUE_2 __maskColor.y
	//掩码的第三个值
	#define GONBEST_MASK_VALUE_3 __maskColor.z
	//掩码的第四个值
	#define GONBEST_MASK_VALUE_4 __maskColor.w
	
	//掩码的值
	#define GONBEST_MASK_VALUE __maskColor
	
	
#else
	//定义Mask坐标
	#define GONBEST_MASK_COORDS(idx1)
	//Mask坐标转移
	#define GONBEST_TRANSFER_MASK(i,o)
	//采样掩码
	#define GONBEST_SAMPLE_MASK(i) 	
	//掩码的第一个值-- 默认为 1
	#define GONBEST_MASK_VALUE_1 1
	//掩码的第二个值-- 默认为 1
	#define GONBEST_MASK_VALUE_2 1
	//掩码的第三个值-- 默认为 1
	#define GONBEST_MASK_VALUE_3 1
	//掩码的第四个值-- 默认为 1
	#define GONBEST_MASK_VALUE_4 1
	//掩码的值
	#define GONBEST_MASK_VALUE float4(1,1,1,1)
	//应用Mask的颜色处理
	#define GONBEST_APPLY_MASK(i,color)
#endif



/************************是否使用颜色分离效果*******************/

#if defined(_GONBEST_COLOR_SCATTER)
	//颜色分离强度
    uniform half _ColorScatterStrength = 0;
	
	#define GONBEST_TEX_SAMPLE_SCATTER(tex,uv,outcolor)\
		fixed2 __GA = tex2D(_MainTex,uv).yw;\
		fixed2 __RA = tex2D(_MainTex, half2(uv.x - _ColorScatterStrength,uv.y)).xw;\
		fixed2 __BA = tex2D(_MainTex, half2(uv.x + _ColorScatterStrength,uv.y)).zw;\
		outcolor = fixed4(fixed3(__RA.x,__GA.x,__BA.x), saturate(__GA.y + __RA.y + __BA.y));		
#else
	#define GONBEST_TEX_SAMPLE_SCATTER(tex,uv,outcolor) 	outcolor = GONBEST_TWO_TEX_SAMPLE(tex,uv);
#endif

/************************颜色变灰的处理*******************/
//获取颜色的灰度
fixed getGrayScale(fixed3 color)
{
	return dot(color,fixed3(0.299, 0.587, 0.114));
}

#if defined(_GONBEST_GRAY_ON)
	uniform float _GrayFactor = 0;
	#define GONBEST_APPLY_GRAY(color)  color.rgb = lerp(color.rgb,(float3)getGrayScale(color.rgb),_GrayFactor);
#else
	#define GONBEST_APPLY_GRAY(color)
#endif
/************************玻璃的处理*******************/
#if defined(_GONBEST_GLASS_ON)	
	#define GONBEST_APPLY_GLASS(color,luminace)  color.a *= luminace;
#else
	#define GONBEST_APPLY_GLASS(color,luminace)
#endif
/************************溶解效果*******************/
#if defined(_GONBEST_DISSOLVE_ON)
	uniform sampler2D _DissolveTex;
	uniform half4 _DissolveTex_ST;
	uniform float _DissolveSoft;

	#define GONBEST_DISSOLVE_COORDS(idx) float3 __dissUV:TEXCOORD##idx;

    // iscustom.w默认为i.texcoord1.y;
	#define GONBEST_TRANSFER_DISSOLVE(i,o,isuv2,iscustom)\
	    half4 __disstexcoord = lerp(i.texcoord, i.texcoord1, step(0.5,isuv2));\
		o.__dissUV.xy = TRANSFORM_TEX(__disstexcoord, _DissolveTex);\
		o.__dissUV.z = lerp(0, (1 - i.texcoord1.y), step(0.5,iscustom));

	//采样掩码
	#define GONBEST_APPLY_DISSOLVE(alpha)\
		float4 __dissolve = tex2D(_DissolveTex,i.__dissUV.xy);\
		float __dissolveAlpha = getGrayScale(__dissolve.xyz)*__dissolve.a + i.__dissUV.z;\
		alpha = lerp(1 - step(__dissolveAlpha, (1 - alpha)*1.01-0.01) , __dissolveAlpha + alpha - 1 , step(0.5,_DissolveSoft));
#else
	#define GONBEST_DISSOLVE_COORDS(idx)
	#define GONBEST_TRANSFER_DISSOLVE(i,o,isuv2,iscustom)
	#define GONBEST_APPLY_DISSOLVE(alpha)
#endif

/************************对视线方向进行修正*******************/
#if defined(_GONBEST_USE_FIXED_VIEW_ON)    
	//实现修正的值,
    uniform float4 _ViewFixedDir = float4(0,0,0,0);
    #define GONBEST_VIEW_FIXED_COORDS(idx) float4 __vfixed:TEXCOORD##idx;
	//这里加上个float3(0,0,1),为了设置方便,默认情况摄像机需要往前看,
    #define GONBEST_TRANSFER_VIEW_FIXED(o) o.__vfixed.xyz = GBNormalizeSafe(mul(float4(_ViewFixedDir.xyz + float3(0,0,1),1),UNITY_MATRIX_V).xyz);  o.__vfixed.w = _ViewFixedDir.w;
    #define GONBEST_VIEW_FIXED_APPLY(i,wv) wv = GBNormalizeSafe(i.__vfixed.xyz + wv);  
#else
    #define GONBEST_VIEW_FIXED_COORDS(idx)
    #define GONBEST_TRANSFER_VIEW_FIXED(o)
    #define GONBEST_VIEW_FIXED_APPLY(i,wv)
#endif

/************************是否对展示区域进行切割 只处理xy两个坐标*******************/
#if defined(_GONBEST_2D_CLIP_RECT_ON)

	uniform float4 _ClipRect;
	uniform half _UseClip;

	//是否在2D的区域当中-- 这里的所有参数都是世界坐标
	inline float __In2DRect(float3 wpos)
	{
		 float2 inside = step(_ClipRect.xy, wpos.xy) * step(wpos.xy, _ClipRect.zw);
		 float v = inside.x * inside.y;
		 float isClip = step(0.5,_UseClip);
		 return lerp(1,v,isClip);
	}
	#define GONBEST_APPLY_IN_CLID_RECT(wpos)  __In2DRect(wpos)
#else		
	#define GONBEST_APPLY_IN_CLID_RECT(wpos) 1
#endif

/************************是否对展示区域进行切割*******************/
#if defined(_GONBEST_MODEL_CLIP_ON)
	//切割的最大长度
	uniform float _ClipMaxLength;
	//切割的百分比
	uniform float _ClipAmount;
	//切割边缘的宽度
	uniform float _EdgeWidth;
	//切割边缘的颜色
	uniform float4 _EdgeColor;
	//内部的颜色
	uniform float4 _InsideColor;

	//定义寄存器
	#define GONBEST_MODEL_CLIP_COORDS(idx) float __clipEdge:TEXCOORD##idx;

	//顶点程序中处理
	#define GONBEST_TRANSFER_MODEL_CLIP_X(v,o) o.__clipEdge = mul(unity_ObjectToWorld,v.vertex.xyz).x - _ClipAmount * _ClipMaxLength;
	#define GONBEST_TRANSFER_MODEL_CLIP_Y(v,o) o.__clipEdge = mul(unity_ObjectToWorld,v.vertex.xyz).y - _ClipAmount * _ClipMaxLength;
	#define GONBEST_TRANSFER_MODEL_CLIP_Z(v,o) o.__clipEdge = mul(unity_ObjectToWorld,v.vertex.xyz).z - _ClipAmount * _ClipMaxLength;

	//边缘的宽度的alpha值(0和1)
	#define GONBEST_GET_MODEL_CLIP_EDGE_VAlUE(i)  step(i.__clipEdge,0) - step(i.__clipEdge,0-_EdgeWidth)
	//显示的alpha值,(0和1)
	#define GONBEST_GET_MODEL_CLIP_VAlUE(i)  step(i.__clipEdge,0)	

	#define GONBEST_MODEL_CLIP_APPLY(i,vface,baseColor,backColor,frontColor)\
			float __full = step(i.__clipEdge,0);\
			float __base = step(i.__clipEdge,0-_EdgeWidth);\
			float __edge = __full - __base;\
			frontColor += __base * baseColor + __edge * _EdgeColor * baseColor ;\
			float4 __inside = __full *  _InsideColor * backColor;\
			frontColor = GONBEST_GET_FINAL_COLOR(vface , __inside, frontColor);

#else		
	#define GONBEST_MODEL_CLIP_COORDS(idx)
	#define GONBEST_TRANSFER_MODEL_CLIP_X(v,o)
	#define GONBEST_TRANSFER_MODEL_CLIP_Y(v,o)
	#define GONBEST_TRANSFER_MODEL_CLIP_Z(v,o)
	#define GONBEST_GET_MODEL_CLIP_EDGE_VAlUE(i) 1
	#define GONBEST_GET_MODEL_CLIP_VAlUE(i) 1
	#define GONBEST_MODEL_CLIP_APPLY(i,vface,baseColor,backColor,frontColor) frontColor = baseColor;
#endif



#endif //GONBEST_WIDGETUTILS_CG_INCLUDED