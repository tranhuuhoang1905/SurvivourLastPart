using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
    public class BloomSetting : GonbestEffectSetting
    {

        /// <summary>
        /// The strength of the bloom filter.
        /// </summary>
        [Min(0f), Tooltip("Strength of the bloom filter. Values higher than 1 will make bloom contribute more energy to the final render.")]
        public float intensity = 0f;

        /// <summary>
        /// Filters out pixels under this level of brightness. This value is expressed in
        /// gamma-space.
        /// </summary>
        [Min(0f), Tooltip("Filters out pixels under this level of brightness. Value is in gamma-space.")]
        public float threshold = 1f ;

        /// <summary>
        /// Makes transition between under/over-threshold gradual (0 = hard threshold, 1 = soft
        /// threshold).
        /// </summary>
        [Range(0f, 1f), Tooltip("Makes transitions between under/over-threshold gradual. 0 for a hard threshold, 1 for a soft threshold).")]
        public float softKnee = 0.5f;

        /// <summary>
        /// Clamps pixels to control the bloom amount. This value is expressed in gamma-space.
        /// </summary>
        [Tooltip("Clamps pixels to control the bloom amount. Value is in gamma-space.")]
        public float clamp = 65472f;

        /// <summary>
        /// Changes extent of veiling effects in a screen resolution-independent fashion. For
        /// maximum quality stick to integer values. Because this value changes the internal
        /// iteration count, animating it isn't recommended as it may introduce small hiccups in
        /// the perceived radius.
        /// </summary>
        [Range(1f, 10f), Tooltip("Changes the extent of veiling effects. For maximum quality, use integer values. Because this value changes the internal iteration count, You should not animating it as it may introduce issues with the perceived radius.")]
        public float diffusion =7f;

        /// <summary>
        /// The tint of the Bloom filter.
        /// </summary>
#if UNITY_2018_1_OR_NEWER
        [ColorUsage(false, true), Tooltip("Global tint of the bloom filter.")]
#else
        [ColorUsage(false, true, 0f, 8f, 0.125f, 3f), Tooltip("Global tint of the bloom filter.")]
#endif
        public Color color = Color.white ;


        /// <inheritdoc />
        protected override bool OnIsEnabledAndSupported(GonbestEffectContext context)
        {
            return enabled && intensity > 0f;
        }

        protected override Type OnPostRendererType()
        {
            return typeof(BloomRenderer);
        }
    }

    
}
