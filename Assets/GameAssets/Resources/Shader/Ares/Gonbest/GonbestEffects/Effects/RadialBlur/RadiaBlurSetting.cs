using System;
using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
    /// <summary>
    /// 径向模糊的设置
    /// </summary>
    public class RadiaBlurSetting : GonbestEffectSetting
    {

        [Range(0, 1), Tooltip("起始位置的x值")]
        public float CenterX = 0.5f;

        [Range(0, 1), Tooltip("起始位置的y值")]
        public float CenterY = 0.5f;

        [Range(0, 10), Tooltip("模糊的方向X")]
        public float ForceX = 1;

        [Range(0, 10), Tooltip("模糊的方向Y")]
        public float ForceY = 1;

        protected override Type OnPostRendererType()
        {
            return typeof(RadiaBlurRenderer);
        }
    }
}
