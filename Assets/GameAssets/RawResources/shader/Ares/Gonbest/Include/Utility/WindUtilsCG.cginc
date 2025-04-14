/*
Author:gzg
Date:2019-08-20
Desc:风的处理
*/
#ifndef GONBEST_WINDUTILS_CG_INCLUDED
#define GONBEST_WINDUTILS_CG_INCLUDED


/*风的处理*/
#if defined(_GONBEST_COMPLEX_WIND_ON)

		//边缘飘起的参数(x:Flutter, y:Freq)
		uniform float2 _WindEdgeFlutter;		
		//风的参数,xyz:风的方向,w:风的强度
		uniform float4 _Wind;	

        //使从0到1的更加平滑
        float4 SmoothCurve( float4 x ) {   
            return x * x *( 3.0 - 2.0 * x );   
        }
        //把一个平面变形为一个三角波的平面([0,0.5]=>[0,1] || [0.5,1]=>[1,0])
        float4 TriangleWave( float4 x ) {   
            return abs( frac( x + 0.5 ) * 2.0 - 1.0 );   
        }
        //把一个平面变形为一个波面.
        float4 SmoothTriangleWave( float4 x ) {   
            return SmoothCurve( TriangleWave( x ) );   
        }
            
        //顶点摆动
        //pos:模型的顶点
        //normal:模型的法线
        //animParams:动作参数
        // 			animParams.x = branch phase  分支的相位 值: 0 
        // 			animParams.y = edge flutter factor 	//边缘飘动的参数 _WindEdgeFlutter
        // 			animParams.z = primary factor		//主参数 顶点颜色 vcolor.a
        // 			animParams.w = secondary factor		//次参数 顶点颜色 vcolor.a
        float4 AnimateVertex2(float4 pos, float3 normal, float4 animParams, float4 wind, float2 time)
        {	
            
            float fDetailAmp = 0.1f; 
            float fBranchAmp = 0.3f;			
            
            //分支的相位(模型上向量float(1,1,1)与坐标Z轴的世界坐标系的向量的夹角??)
            // float fBranchPhase = animParams.x;
            //顶点的相位(模型上顶点与float(XXX)的夹角)
            float fVtxPhase = dot(pos.xyz, animParams.y + animParams.x);
            
            //求波
            // x is used for edges; y is used for branches
            float2 vWavesIn = time  + float2(fVtxPhase, animParams.x );
            
            //求频率波
            // 1.975, 0.793, 0.375, 0.193 are good frequencies
            float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
            
            //重新处理波
            vWaves = SmoothTriangleWave( vWaves );		
            
            float2 vWavesSum = vWaves.xz + vWaves.yw;

            //边缘和分支,弯曲--根据法线来获得弯曲度
            // Edge (xz) and branch bending (y)
            float3 bend = animParams.y * 0.1 * normal.xyz;
            bend.y = animParams.w * 0.3;
            
            //为顶点增加弯曲
            pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 

            // Primary bending
            // Displace position  //替换位置
            pos.xyz += animParams.z * wind.xyz;
            
            return pos;
        }	
		
		#define GONBEST_TRANSFER_WIND(i) \
				float4	wind;	\
				float		bendingFact	= i.color.a;	\
				wind.xyz	= mul((float3x3)unity_WorldToObject,_Wind.xyz);	\
				wind.w		= _Wind.w  * bendingFact;	\
				float4	windParams	    = float4(dot(unity_ObjectToWorld[3].xyz, 1),0.5,bendingFact.xx);	\
				float 	windTime 		= _Time.y * float2(0.5,1);	\
				i.vertex				= AnimateVertex2(i.vertex,i.normal,windParams,wind,windTime);		
			
#elif defined(_GONBEST_SIMPLE_WIND_ON)
		//频率
		uniform float _Frequency;
		//方向
		uniform float _Direction;		
		
		#define GONBEST_TRANSFER_WIND(i) i.vertex.xyz += float3(sin( _Time.y * _Direction ),0,sin( _Time.y * _Direction + 3.14 * 0.5f )) * i.color.a * _Frequency;
#else
		#define GONBEST_TRANSFER_WIND(i) 
#endif

#endif //GONBEST_WINDUTILS_CG_INCLUDED
