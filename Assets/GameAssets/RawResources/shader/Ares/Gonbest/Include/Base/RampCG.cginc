/*=============================================================
Author:gzg
Date:2019-09-03
Desc:这里通过程序来进行梯度计算，不过很多时候是使用RampLut图进行采样处理。
=============================================================*/
#ifndef GONBEST_RAMP_CG_INCLUDED
#define GONBEST_RAMP_CG_INCLUDED

#include "MathCG.cginc"

//通过线性插值来计算阶梯,这个阶梯可以进行过度处理
inline float RampTwoStep(float value,float threshold,float smooth)
{
    return GBLinearstep(threshold-smooth,threshold+smooth,value);
}

inline float RampTwoStepEx(float value,float threshold,float smooth)
{
    return GBSmoothstep(threshold-smooth,threshold+smooth,value);
}



//通过floor来计算阶梯,这里的阶梯不能有过度处理
/*
value:需要处理的数据
stepheight:每个阶梯之间的高度 一般都是0.5
offset1:在某个区间x=>[0,1]内,小数部分的修改,在x轴方向进行位移阶梯,整数部分的修改,就是在Y轴方向位移阶梯
offset2:在某个区间x=>[0,1]内,修改阶梯在Y轴方向的位移

函数:
f(x) = floor(x+a)*step+b;

                    |
                    |
                    |                  ------
                    |
                    |            ------
                    |
                    |      ------
                    |
                    |------        
                    |        
--------------------|--------------------------------                           
                    |    
                    |
                    |
                    |
                    |
*/
inline float FloorStep(float value,float stepheight,float offset1,float offset2)
{
    return floor(value + offset1) * stepheight + offset2;
}

#endif //GONBEST_RAMP_CG_INCLUDED