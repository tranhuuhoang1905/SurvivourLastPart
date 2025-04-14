/*
Author:gzg
Date:2019-08-20
Desc:Ohttp://www.52vr.com/article-1087-1.html
	有趣的一点是我们如何计算环境BRDF，对于高端平台来说，它是使用Monte Carlo整合来进行预计算的，并存储于二维LUT中。
	对移动平台的硬件来说，依赖于贴图提取非常消耗系统资源，更糟的是，OpenGL ES2的8个采样器的限制造成了极大的使用限制。
	使用这个LUT来处理采样器是完全不行的。我转而基于Dimitar Lazarov的作品来作出了类似的解析版本。
	形式类似，但根据我们的着色模型和粗糙度参数进行了调整。函数列于下方：
*/
#ifndef GONBEST_ENVBRDF_A_CG_INCLUDED
#define GONBEST_ENVBRDF_A_CG_INCLUDED


//环境BRDF的近似公式
inline float3 EnvBRDFApprox(float3 SpecularColor, float Roughness, float NoV)
{
	float4 c0 = float4(-1 , -0.0275 , -0.572 , 0.022);
	float4 c1 =  float4( 1 , 0.0425 , 1.04 , -0.04);	
	float4 r = Roughness * c0 + c1;
	float a004= min(r.x * r.x , exp2(-9.28 * NoV) ) * r.x  + r.y;
	float2 AB = float2(-1.04 , 1.04) * a004 + r.zw;
	return SpecularColor * AB.x + AB.y;
}


//非金属的环境近似函数 -- 非金属 SpecularColor = 0.04;
half EnvBRDFApproxNonmetal( half Roughness, half NoV )
{
    // Same as EnvBRDFApprox( 0.04, Roughness, NoV )
    const half2 c0 = { -1, -0.0275 };
   const half2 c1 = { 1, 0.0425 };
   half2 r = Roughness * c0 + c1;
   return min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
}
	


#endif //GONBEST_ENVBRDF_A_CG_INCLUDED