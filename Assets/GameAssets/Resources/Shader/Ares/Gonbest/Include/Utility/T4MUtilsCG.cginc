/*
Author:gzg
Date:2019-08-20
Desc:T4M的层纹理读取处理
*/

#ifndef GONBEST_T4MUTILS_CG_INCLUDED
#define GONBEST_T4MUTILS_CG_INCLUDED

//顺序不可以变化
#if defined(_GONBEST_T4M_4_ON) //支持有四个纹理
	//默认打开3张纹理	
	#ifndef _GONBEST_T4M_3_ON
		#define _GONBEST_T4M_3_ON
	#endif
		//定义变量
		uniform sampler2D _Splat3;
		#if _GONBEST_T4M_NORMAL_ON	
		uniform sampler2D _Splat3_BumpMap;
		#endif
		uniform half4 _Splat3_ST;
		
		//定义UV寄存器
		#define GONBEST_T4M_4_COORD(idx1) half2 uv4 : TEXCOORD##idx1;
		
		//计算UV
		#define GONBEST_TRANSFER_T4M_4(i,o) \
						o.uv4 = i.texcoord.xy * _Splat3_ST.xy;
						
		//应用颜色				
		#define GONBEST_APPLY_T4M_4(i,ctrl,color) \
						fixed4 lay4 = tex2D( _Splat3, i.uv4 ); \
						color += ctrl.a * lay4;
								//应用颜色				
		#define GONBEST_APPLY_T4M_NORMAL_4(i,ctrl,color,normal) \
						fixed4 lay4 = tex2D( _Splat3, i.uv4 ); \
						color += ctrl.a * lay4;\
						fixed4 lay4normal = tex2D(_Splat3_BumpMap,i.uv4);\
						normal +=  lay4normal;

#else
		#define GONBEST_T4M_4_COORD(idx1)
		#define GONBEST_TRANSFER_T4M_4(i,o)
		#define GONBEST_APPLY_T4M_4(i,ctrl,color)
		#define GONBEST_APPLY_T4M_NORMAL_4(i,ctrl,color,normal)
#endif


#if defined(_GONBEST_T4M_3_ON) //支持有三个纹理
	//默认打开2张纹理
	#ifndef _GONBEST_T4M_2_ON
		#define _GONBEST_T4M_2_ON
	#endif
	
		uniform sampler2D _Splat2;
	#if _GONBEST_T4M_NORMAL_ON		
		uniform sampler2D _Splat2_BumpMap;
	#endif
		uniform half4 _Splat2_ST;
		
		//定义UV寄存器
		#define GONBEST_T4M_3_COORD(idx1) half2 uv3 : TEXCOORD##idx1;
		
		//计算UV
		#define GONBEST_TRANSFER_T4M_3(i,o) \
					o.uv3 = i.texcoord.xy * _Splat2_ST.xy;

		//应用颜色				
		#define GONBEST_APPLY_T4M_3(i,ctrl,color) \
					fixed4 lay3 = tex2D( _Splat2, i.uv3 ); \
					color += ctrl.b * lay3;

		//应用颜色				
		#define GONBEST_APPLY_T4M_NORMAL_3(i,ctrl,color,normal) \
					fixed4 lay3 = tex2D( _Splat2, i.uv3 ); \
					color += ctrl.b * lay3;\
					fixed4 lay3normal = tex2D(_Splat2_BumpMap,i.uv3);\
					normal += ctrl.b* lay3normal;
#else
		//定义UV寄存器
		#define GONBEST_T4M_3_COORD(idx1)
		//计算UV
		#define GONBEST_TRANSFER_T4M_3(i,o)
		//应用颜色				
		#define GONBEST_APPLY_T4M_3(i,ctrl,color)
		#define GONBEST_APPLY_T4M_NORMAL_3(i,ctrl,color,normal)
#endif

#if defined(_GONBEST_T4M_2_ON) //支持两个纹理

	//定义两张纹理
	uniform sampler2D _Splat0;
	uniform half4 _Splat0_ST;
	uniform sampler2D _Splat1;
	uniform half4 _Splat1_ST;

	#if _GONBEST_T4M_NORMAL_ON	
		uniform sampler2D _Splat0_BumpMap;
		uniform sampler2D _Splat1_BumpMap;	
	#endif
		
	//定义UV寄存器
	#define GONBEST_T4M_2_COORD(idx1) half4 uv1 : TEXCOORD##idx1; 
					
	
	//计算UV
	#define GONBEST_TRANSFER_T4M_2(i,o) \
					o.uv1.xy = i.texcoord.xy * _Splat0_ST.xy; \
					o.uv1.zw = i.texcoord.xy * _Splat1_ST.xy; 
	
	//应用颜色			
	#define GONBEST_APPLY_T4M_2(i,ctrl,color) \
					fixed4 lay1 = tex2D( _Splat0, i.uv1.xy ); \
					fixed4 lay2 = tex2D( _Splat1, i.uv1.zw ); \
					color += ctrl.r * lay1;\
					color += ctrl.g * lay2;
						//应用颜色			
	#define GONBEST_APPLY_T4M_NORMAL_2(i,ctrl,color,normal) \
					fixed4 lay1 = tex2D( _Splat0, i.uv1.xy ); \
					fixed4 lay2 = tex2D( _Splat1, i.uv1.zw ); \
					color += ctrl.r * lay1;\
					color += ctrl.g * lay2;\
					fixed4 lay1normal = tex2D(_Splat0_BumpMap,i.uv1.xy);\
					normal += ctrl.r * lay1normal;\
					fixed4 lay2normal = tex2D(_Splat1_BumpMap,i.uv1.zw);\
					normal += ctrl.g * lay2normal;
#else
	//定义UV寄存器
	#define GONBEST_T4M_2_COORD(idx1)
	//计算UV
	#define GONBEST_TRANSFER_T4M_2(i,o)
	//应用颜色			
	#define GONBEST_APPLY_T4M_2(i,ctrl,color)
	#define GONBEST_APPLY_T4M_NORMAL_2(i,ctrl,color,normal)
#endif

#endif

