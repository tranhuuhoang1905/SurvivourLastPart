/*
Author:gzg
Date:2019-08-20
Desc:Cook-Torrance的高光公式
*/
#ifndef GONBEST_COOKTORRANCE_CG_INCLUDED
#define GONBEST_COOKTORRANCE_CG_INCLUDED
#include "../Base/CommonCG.cginc"
/*
Cook-Torrance 模型
用模型模拟了金属和塑料材质，考虑到了入射角变化时发生的颜色偏移。

基本反射模型：
    f(l,v)=D(h)F(v,h)G(l,v,h)/(4(n⋅l)(n⋅v))
以及BRDF公式：
    BRDF = kD / pi + kS * (D * V * F) / 4
然后拆分公式，一项项的实现。
    D——微表面分布项
    V——遮挡可见性项
    F——菲涅尔反射项
    kD——漫反射系数
    kS——镜面反射系数
注意:V(Visibility)项即G(l,v,h)/(4(n⋅l)(n⋅v))的集合。


另外: 这个模型被放弃了.
*/
#endif //GONBEST_COOKTORRANCE_CG_INCLUDED