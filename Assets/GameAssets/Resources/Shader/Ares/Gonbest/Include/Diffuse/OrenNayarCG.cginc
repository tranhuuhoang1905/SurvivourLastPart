/*
Author:gzg
Date:2019-08-20
Desc:Oren-Nayar模型的漫反射计算公式
    对于体反射来说，lambertian的模型不能正确体现其效果。

    本模型主要对粗糙表面的物体建模，比如石膏、沙土、陶瓷还有布。

    用了一系列的lambert微面元，考虑了微小面元之间的相互遮挡（shadowing and masking）和互相反射照明。

    一些粗糙的表面具有很大程度逆反射的性质(反射向量和入射光线在发现的同一边)。
*/
#ifndef GONBEST_ORENNAYAR_CG_INCLUDED
#define GONBEST_ORENNAYAR_CG_INCLUDED
#include "../Base/CommonCG.cginc"

float OrenNayarDiffuse(half lv,half nl,half nv,float roughness, float albedo) 
{
  float s = lv - nl * nv;
  float t = lerp(1.0, max(nl, nv), step(0.0, s));

  float sigma2 = roughness * roughness;
  float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
  float B = 0.45 * sigma2 / (sigma2 + 0.09);

  return albedo * max(0.0, nl) * (A + B * s / t) * GONBEST_INV_PI;
}
#endif //GONBEST_ORENNAYAR_CG_INCLUDED