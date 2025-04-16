/*
Author:gzg
Date:2019-08-20
Desc:边缘光的函数定义
*/
#ifndef GONBEST_RIMLIGHT_CG_INCLUDED
#define GONBEST_RIMLIGHT_CG_INCLUDED

//受散射光影响的边缘光处理
inline float GBRimTerm(float NoV, float NoL, float PowerValue)
{
    float rim = 1 - NoV;
    return pow(rim, PowerValue) *  NoL;
}

//基础的边缘光处理
inline float GBRimTermBase(float NoV,float PowerValue)
{
    float rim = 1 - NoV;
    return pow(rim, PowerValue);
}



#endif //GONBEST_RIMLIGHT_CG_INCLUDED