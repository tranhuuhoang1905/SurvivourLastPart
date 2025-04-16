Shader "Ares/Animation/AlphaScrollingTwoUV_Add" 
{
	Properties
	{
		_Color( "Tint Color", Color ) = (1, 1, 1, 1)
		_ColorMultiplier("Color Multipler",range(0,10)) = 1
		_MainTex( "Texture 1", 2D ) = "(0,0,0,0)" {}
		_DetailTex( "Texture 2", 2D ) = "(0,0,0,0)" {}
		_ScrollSpeed ("Tex1(x,y),Tex2(z,w)", Vector) = (2,2,2,2)
		_UseClip("UseClip",float) = 0
		_ClipRect("ClipRect",Vector)= (-50000,-50000,50000,50000)								
	}

	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "GonbestBloomType"="BloomMask"}		
		UsePass "Gonbest/Legacy/ScrollUVHelper/TWO&ADD"
	}
	Fallback "Gonbest/FallBack/FBNothing"
	
}
