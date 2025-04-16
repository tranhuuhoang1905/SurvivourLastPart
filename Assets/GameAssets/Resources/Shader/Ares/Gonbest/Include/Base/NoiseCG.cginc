/*=============================================================
Author:gzg
Date:2019-08-20
Desc:噪音的处理
=============================================================*/

#ifndef GONBEST_NOISE_CG_INCLUDED
#define GONBEST_NOISE_CG_INCLUDED

    fixed2 randPos(fixed2 value)
    {
        fixed2 pos = fixed2(dot(value, fixed2(127.1, 337.1)), dot(value, fixed2(269.5, 183.3)));
        pos = frac(sin(pos) * 43758.5453123);
        return pos;
    }

    fixed2 randPos(fixed2 value)
    {
        fixed2 pos = fixed2(dot(value, fixed2(127.1, 337.1)), dot(value, fixed2(269.5, 183.3)));
        pos = frac(sin(pos) * 43758.5453123);
        return pos;
    }

    float worleyNoise(float2 uv)
    {
        fixed2 index = floor(uv);
        float2 pos = frac(uv);
        float d = 1.5;
        for(int i = -1; i < 2; i++)
            for (int j = -1; j < 2; j++)
            {
                fixed2 p = randPos(index + fixed2(i, j));
                float dist = length(p + fixed2(i, j) - pos);
                d = min(dist, d);
            }
        return d;
    }

    float2 worleyNoise2(float2 uv)//泰森多边形
    {
        fixed2 index = floor(uv);
        float2 pos = frac(uv);
        float2 d = float2(1.5, 1.5);
        for (int i = -1; i < 2; i++)
            for (int j = -1; j < 2; j++)
            {
                fixed2 p = randPos(index + fixed2(i, j));
                float dist = length(p + fixed2(i, j) - pos);
                if (dist < d.x)
                {
                    d.y = d.x;
                    d.x = dist;
                }
                else
                    d.y = min(dist, d.y);
            }
        return d;
    }


    fixed2 randVec(fixed2 value)
    {
        fixed2 vec = fixed2(dot(value, fixed2(127.1, 337.1)), dot(value, fixed2(269.5, 183.3)));
        vec = -1 + 2 * frac(sin(vec) * 43758.5453123);
        return vec;
    }

    float perlinNoise(float2 uv)
    {
        float a, b, c, d;
        float x0 = floor(uv.x); 
        float x1 = ceil(uv.x); 
        float y0 = floor(uv.y); 
        float y1 = ceil(uv.y); 
        fixed2 pos = frac(uv);

        a = dot(randVec(fixed2(x0, y0)), pos - fixed2(0, 0));
        b = dot(randVec(fixed2(x0, y1)), pos - fixed2(0, 1));
        c = dot(randVec(fixed2(x1, y1)), pos - fixed2(1, 1));
        d = dot(randVec(fixed2(x1, y0)), pos - fixed2(1, 0));

        float2 st = 6 * pow(pos, 5) - 15 * pow(pos, 4) + 10 * pow(pos, 3);
        a = lerp(a, d, st.x);
        b = lerp(b, c, st.x);
        a = lerp(a, b, st.y);
        return a;
    }

    float fbm(float2 uv)
    {
        float f = 0;
        float a = 1;
        for(int i = 0; i < 3; i++)
        {
            f += a * perlinNoise(uv);
            uv *= 2;
            a /= 2;
        }
        return f;
    }

#endif