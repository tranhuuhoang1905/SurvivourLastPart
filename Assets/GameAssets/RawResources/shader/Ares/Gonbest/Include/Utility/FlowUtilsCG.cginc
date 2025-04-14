/*
Author:gzg
Date:2019-08-20
Desc:各种流动处理包括,包括UV滚动,光流动,光闪烁等等
*/

#ifndef GONBEST_FLOWUTILS_CG_INCLUDED
#define GONBEST_FLOWUTILS_CG_INCLUDED


/*******************模型上流光的处理***************************/
#if defined(_GONBEST_FLOW_ON)	
	//流光是否使用uv2 -- 注意使用这个的时候,与lightmap会冲突
	uniform float _FlowUseUV2;
    //流光图	
	uniform sampler2D _FlowTex;  
	//uniform float4 _FlowTex_ST; //噪音图
    //流动速度
	uniform half _FlowSpeed;	
    //流光的调整颜色1	
	uniform fixed4 _FlowColor;	
    //流光的调整颜色2
	uniform fixed4 _FlowColor2;
    //平铺值
    uniform half _FlowTileCount;	
	//流光的强度
	uniform half _FlowStrength;
	

	//使用流光的UV
	#define GONBEST_USE_FLOW_UV(uv1,uv2)  lerp(uv1,uv2,step(0.5,_FlowUseUV2))

	#if defined(_GONBEST_FLOW_FLUX_ON)	
		/*
			baseColor:主纹理颜色值
			soffset:顶点计算的偏移值				
		*/
		inline fixed3 _addon_fx_fluxay( float3 baseColor, float2 soffset) 
		{
			half2 uvW = abs( frac( ( baseColor.rg + soffset ) * 0.5 ) * 2.0 - 1.0 );
			half2 uvA = abs( frac( ( baseColor.gb + soffset ) * 0.37 ) * 2.0 - 1.0 );
			fixed4 color = lerp(_FlowColor, _FlowColor2, tex2D( _FlowTex, uvW ).r );		
			color.a *= tex2D( _FlowTex, uvA ).r;
			return color.rgb * color.a;
		}
		
		//处理流光的UV值-->i:vert的输入(vertex),o:vert的输出(uv需要被定义为float4) ( fmod( _Time.x, 600 ) - 300 )
		#define GONBEST_CALC_FLOW_UV(i,uv) uv.xy * _FlowTileCount + _FlowSpeed * frac(_Time.x) * 0.8
		//应用流光的颜色-->i:frag的输入(uv需要被定义为float4),tintColor:其他颜色值,color:颜色输入输出, factor:流光的显示参数 -- 通过mask纹理读取来的
		#define GONBEST_APPLY_FLOW(flowuv,color,factor) color.rgb += _addon_fx_fluxay( color.rgb , flowuv )*factor * _FlowStrength;

	#elif defined(_GONBEST_FLOW_DISTORT_ON)
		uniform sampler2D _FlowNoiseTex; //噪音图		
		uniform float _FlowForceX;	//x方向的力
		uniform float _FlowForceY;    //y方向的力
		
        //uv值,通过噪音纹理扭曲流光
		inline fixed3 _flow_distort(float2 uv,float2 speed, float factor)
		{
			fixed4 offsetColor1 = tex2D(_FlowNoiseTex, uv  + speed);
			fixed4 offsetColor2 = tex2D(_FlowNoiseTex, uv  - speed);
			uv.x += ((offsetColor1.r + offsetColor2.r) - 1) * _FlowForceX;
			uv.y += ((offsetColor1.r + offsetColor2.r) - 1) * _FlowForceY;
			return lerp(_FlowColor.rgb,_FlowColor2.rgb,factor) * tex2D( _FlowTex, uv).rgb;
		}
		#define GONBEST_CALC_FLOW_UV(i,uv) uv.xy * _FlowTileCount
		//应用流光的颜色-->i:frag的输入color:颜色输入输出, factor:流光的显示参数 -- 通过mask纹理读取来的
		#define GONBEST_APPLY_FLOW(flowuv,color,factor) color.rgb += _flow_distort(flowuv,frac(_Time.xx*_FlowSpeed),factor) * _FlowStrength;
	#elif defined(_GONBEST_FLOW_BLINK_ON)
	   //通过流动实现噗灵噗灵的效果
		inline fixed3 _flow_blink(float2 uv,float speed,float power,float factor)
		{
			float s = _Time.x * speed + 0.1;
			fixed3 c1 = tex2D(_FlowTex,uv + s);
			fixed3 c2 = tex2D(_FlowTex,uv * 0.9 - s + 0.5);
			return c1 * c2  * _FlowColor * power * factor * 10;
		}
		#define GONBEST_CALC_FLOW_UV(i,uv) uv.xy * _FlowTileCount
		//应用流光的颜色-->i:frag的输入color:颜色输入输出, factor:流光的显示参数 -- 通过mask纹理读取来的
		#define GONBEST_APPLY_FLOW(flowuv,color,factor) color.rgb += _flow_blink(flowuv , _FlowSpeed , _FlowStrength, factor);
	#else
		uniform half _FlowType;		//流光的样式
		/*
		//获取纹理移动的UV值
		//vertex:顶点
		//uv:uv值
		//type:移动类型
				1.顶点xy移动
				2.顶点xz移动
				3.顶点yz移动
				4.uv移动
		//speed:流动速度
		//titleCount:平铺值		
		*/	
		inline float2 _getFlowUV(float4 vertex, float2 uv, float type, float speed, float tileCount)
		{
		
			float2 fuv =  step(type,1) * vertex.xy 
								+ step(1.0001, type) * step(type,2) * vertex.xz  
								+ step(2.0001,type) * step(type,3) * vertex.yz 
								+ step(3.0001,type) * uv.xy				
								+ frac(_Time.xx * speed);		
			fuv =fuv * tileCount;
			return fuv;	
		}
		
		//处理流光的UV值-->i:vert的输入(vertex),o:vert的输出(uv需要被定义为float4)
		#define GONBEST_CALC_FLOW_UV(i,uv) _getFlowUV(i.vertex,uv.xy ,_FlowType,_FlowSpeed,_FlowTileCount)	
		//应用流光的颜色-->i:frag的输入(uv需要被定义为float4),tintColor:其他颜色值,color:颜色输入输出, factor:流光的显示参数 -- 通过mask纹理读取来的
		#define GONBEST_APPLY_FLOW(flowuv,color,factor)\
			float4 __flow = tex2D( _FlowTex,flowuv);\
			color.rgb += __flow.rgb * __flow.a * lerp(_FlowColor.rgb,_FlowColor2.rgb,factor) * _FlowStrength;
	#endif
	
#else //定义空宏
	#define GONBEST_USE_FLOW_UV(uv1,uv2) float2(0,0)
    #define GONBEST_CALC_FLOW_UV(i,uv) float2(0,0)
	#define GONBEST_APPLY_FLOW(flowuv,color,factor) 
#endif

/*******************定义流光中,一个扫光***************************/
#if defined(_GONBEST_FLOW_FELIGHTWIPE_ON)

	//扫光的速度
	float _FELightWipeSpeed = 1;
	//扫光的间隔
	float _FELightWipeInterval = 1;
	//扫光的宽度
	float _FELightWipeWidth = 0.3;	
	//扫光的颜色
	float3 _FELightWipeColor = float3(1,1,1);

	//计算扫光的值
	inline float _calcFELightWipeValue(float uvOffset,float speed,float interval,float width)
	{
		uvOffset = speed < 0 ? (1-uvOffset) : uvOffset;
		float feValue = abs(speed) +interval;
		feValue = frac(_Time.y / feValue) * feValue ;             
		feValue = max(0, feValue - interval);
		feValue = feValue / abs(speed);
		feValue = (1 + width) * feValue;
		feValue = (feValue - uvOffset) / width;
		feValue = (feValue-1)*2 + 1;
		feValue = 1 - sqrt(abs(feValue));
		return max(0,feValue);
	}	
	#define GONBEST_APPLY_FLOW_FELIGHTWIPE(uv,color,factor) color.xyz += _calcFELightWipeValue(uv.x,_FELightWipeSpeed,_FELightWipeInterval,_FELightWipeWidth) * _FELightWipeColor.xyz * factor;
#else
	#define GONBEST_APPLY_FLOW_FELIGHTWIPE(uv,color,factor)
#endif

/*******************模型上颜色闪烁的处理***************************/
#if defined(_GONBEST_FLASH_ON)		
    uniform float _FlashSpeed;
    uniform float4 _FlashColor;   
	#if defined(_GONBEST_FLASH_TEX_ON)
		uniform sampler2D _FlashTex;
    	#define GONBEST_APPLY_FLASH(color,factor,uv) color.rgb = lerp(color.rgb, _FlashColor.rgb * tex2D(_FlashTex,uv).rgb ,_FlashColor.a * factor * (saturate(abs(frac(_FlashSpeed*_Time.y)-0.5)*4-0.5)));
	#else
		#define GONBEST_APPLY_FLASH(color,factor,uv) color.rgb = lerp(color.rgb, _FlashColor.rgb , _FlashColor.a * factor * (saturate(abs(frac(_FlashSpeed*_Time.y)-0.5)*4-0.5)));
	#endif
#else
    #define GONBEST_APPLY_FLASH(color,factor,uv)
#endif

/*******************纹理滚动***************************/
#if defined(_GONBEST_ONE_SCROLL_UV_ON)  //处理一个UV的滚动

	//纹理滚动速度 (x,y):纹理滚动速度,z:Alpha的删错速度,w: <0 则不处理alpha闪烁,>0做alpha闪烁
	uniform half4 _ScrollSpeed;
	//处理UV--默认情况 alpha 不做改变
	#define GONBEST_TRANSFER_SCROLL_UV(i,o)  \
			o.uv.xy += frac(_ScrollSpeed.xy * _Time.xx) ;  \
			half f = step(0,_ScrollSpeed.w); \
			o.uv.z =  (sin(_Time.y * _ScrollSpeed.z) * 0.5 + 0.5) * f + (1-f); 
	
	//对颜色做处理
	#define GONBEST_APPLY_SCROLL_UV(i,color) color.a *= i.uv.z;
#elif defined(_GONBEST_TWO_SCROLL_UV_ON) //处理两个UV的滚动

	//纹理滚动速度 (x,y):第一个纹理滚动速度,(z,w):第二个纹理的滚动速度
	uniform half4 _ScrollSpeed;
	//第二个纹理
	uniform sampler2D _DetailTex;
	uniform half4 _DetailTex_ST;
	//处理UV
	#define GONBEST_TRANSFER_SCROLL_UV(i,o) \
					o.uv.zw = TRANSFORM_TEX(i.texcoord, _DetailTex);	\
					o.uv += frac(_ScrollSpeed * _Time.xyxy);
					
	//应用第二个UV
	#define GONBEST_APPLY_SCROLL_UV(i,color) color *= GONBEST_TWO_TEX_SAMPLE(_DetailTex,i.uv.zw);
#else
	//处理UV
    #define GONBEST_TRANSFER_SCROLL_UV(i,o)
	#define GONBEST_APPLY_SCROLL_UV(i,color)
#endif

//UV扭曲的处理
#ifdef _GONBEST_UV_DISTORT_ON
	uniform sampler2D _NoiseTex;
	uniform fixed _TimeScale;
	uniform fixed _DistortScaleX;
	uniform fixed _DistortScaleY;
	
	half2 distort_uv( half2 uv ) {
		fixed4 offsetColor1 = tex2D( _NoiseTex, uv + _Time.xz * _TimeScale );
		fixed4 offsetColor2 = tex2D( _NoiseTex, uv + _Time.yx * _TimeScale );
		fixed offset = ( offsetColor1.r + offsetColor2.r ) - 1;
		uv.x += offset * _DistortScaleX;
		uv.y += offset * _DistortScaleY;
		return uv;
	}
	#define GONBEST_DISTORT_UV(uv) distort_uv(uv)
#else
	#define GONBEST_DISTORT_UV(uv) (uv)
#endif

#endif