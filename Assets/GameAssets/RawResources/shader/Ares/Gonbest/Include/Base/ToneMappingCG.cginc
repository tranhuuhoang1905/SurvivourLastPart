/*=============================================================
Author:gzg
Date:2019-08-20
Desc:颜色调色板处理,HDR转换到LDR的过程就是使用Tonemapping，一些卡通渲染也由一些使用光影颜色映射来处理。

Tone mapping进化论
https://zhuanlan.zhihu.com/p/21983679
=============================================================*/
#ifndef GONBEST_TONEMAPPING_CG_INCLUDED
#define GONBEST_TONEMAPPING_CG_INCLUDED


/*1.经验派:
其中color是线性的HDR颜色，
adapted_lum是根据整个画面统计出来的亮度。
MIDDLE_GREY表示把什么值定义成灰。这个值就是纯粹的magic number了，根据需要调整。
Reinhard的曲线是这样的，可以看出总体形状是个S型。
这种tone mapping的方法更多地来自于经验，没什么原理在后面。
所以就姑且称它为经验派吧。它的优点是简单直接，把亮的变暗，暗的变量。
这样暗处和亮处细节就都出来了。
但缺点也很明显，就是灰暗。个个颜色都朝着灰色的方向被压缩了，画面像蒙了一层纱。
虽然有这样的缺点，但那几年一来用HDR渲染的游戏少，二来大家不知道别的方法，所以就一直用着Reinhard tone mapping。 
*/
inline float3 ReinhardToneMapping(float3 color, float adapted_lum) 
{
    const float MIDDLE_GREY = 1;
    color *= MIDDLE_GREY / adapted_lum;
    return color / (1.0f + color);

}

/*
2.粗暴派:
到了2007年，孤岛危机（Crysis）的CryEngine 2，为了克服Reinhard灰暗的缺点，开始用了另一个tone mapping的方法。
前面提到了tone mapping就是个S曲线，那么既然你要S曲线，我就搞出一个S曲线。
这个方法更简单，只要一行，而且没有magic number。
用一个exp来模拟S曲线。

CE的曲线中间的区域更偏向于小的方向，这部分曲线也更陡。
这个方法得到的结果比Reinhard有更大的对比度，颜色更鲜艳一些，虽然还是有点灰。

CE的方法在于快速，并且视觉效果比Reinhard。但是这个方法纯粹就是凑一个函数，没人知道应该如何改进。属于粗暴地合成。
*/
inline float3 CEToneMapping(float3 color, float adapted_lum) 
{
    return 1 - exp(-adapted_lum * color);
}



/*
3.拟合派
到了2010年，Uncharted 2公开了它的tone mapping方法，称为Filmic tone mapping。
当年我也写过一篇博客讲KlayGE切换到Filmic tone mapping的事情。
这个方法的本质是把原图和让艺术家用专业照相软件模拟胶片的感觉，人肉tone mapping后的结果去做曲线拟合，得到一个高次曲线的表达式。
这样的表达式应用到渲染结果后，就能在很大程度上自动接近人工调整的结果。

最后出来的曲线是这样的。总的来说也是S型，但增长的区域很长。

从结果看，对比度更大，而且完全消除了灰蒙的感觉。 

那些ABCDEF都是多项式的系数，而WHITE是个magic number，表示白色的位置。
这个方法开启了tone mapping的新路径，让人们知道了曲线拟合的好处。
并且，其他颜色空间的变换，比如gamma矫正，也可以一起合并到这个曲线里来，一次搞定，不会增加额外开销。
缺点就是运算量有点大，两个多项式的计算，并且相除。

因为Filmic tone mapping的优异表现，大部分游戏都切换到了这个方法。包括CE自己，也在某个时候完成了切换。 
*/
inline float3 F(float3 x)
{
	const float A = 0.22f;
	const float B = 0.30f;
	const float C = 0.10f;
	const float D = 0.20f;
	const float E = 0.01f;
	const float F = 0.30f;
 
	return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}
 
inline float3 Uncharted2ToneMapping(float3 color, float adapted_lum)
{
	const float WHITE = 11.2f;
	return F(1.6f * adapted_lum * color) / F(WHITE);

}

/*
4.你们都是渣渣派:
在大家以为Filmic tone mapping会统治很长时间的时候，江湖中来了一位异域高手。
他认为，你们这帮搞游戏/实时图形的，都是渣渣。
让我们电影业来教你们什么叫tone mapping。
这位高手叫美国电影艺术与科学学会，就是颁布奥斯卡奖的那个机构。
不要以为他们只是个评奖的单位，美国电影艺术与科学学会的第一宗旨就是提高电影艺术与科学的质量。

他们发明的东西叫:
Academy Color Encoding System（ACES）,
是一套颜色编码系统，或者说是一个新的颜色空间.
它是一个通用的数据交换格式，一方面可以不同的输入设备转成ACES，
另一方面可以把ACES在不同的显示设备上正确显示。
不管你是LDR，还是HDR，都可以在ACES里表达出来。
这就直接解决了VDR的问题，不同设备间都可以互通数据。

color:是线性的HDR颜色，
adapted_lum:是根据整个画面统计出来的亮度
*/
inline float3 ACESToneMapping(float3 color, float adapted_lum)
{
	const float A = 2.51f;
	const float B = 0.03f;
	const float C = 2.43f;
	const float D = 0.59f;
	const float E = 0.14f;
 
	color *= adapted_lum;
	return (color * (A * color + B)) / (color * (C * color + D) + E);
}

#endif