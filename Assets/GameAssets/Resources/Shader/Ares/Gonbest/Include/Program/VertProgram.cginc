/*
Author:gzg
Date:2019-08-20
Desc:常用的顶点处理函数
*/

struct vdata {
	float4 vertex:POSITION;
	float2 texcoord:TEXCOORD0;
};

struct v2f {
    float4 pos : POSITION;
    half2 uv : TEXCOORD0;
};

//最简单的顶点处理方式
v2f vert_simple( vdata v ) {

    v2f o = ( v2f )0;
    o.pos = UnityObjectToClipPos( v.vertex );
    o.uv = v.texcoord;
    return o;
}