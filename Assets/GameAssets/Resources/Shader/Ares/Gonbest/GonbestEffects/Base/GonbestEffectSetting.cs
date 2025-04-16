using System;
using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
    [Serializable]
    public abstract class GonbestEffectSetting: ScriptableObject
    {
        [SerializeField]
        public bool enabled = false;

        public Type PostRendererType()
        {
            return OnPostRendererType();
        }

        private void OnEnable()
        {
            
        }

        private void OnDisable()
        {
            
        }
        
        public bool IsEnabledAndSupported(GonbestEffectContext context)
        {
            return OnIsEnabledAndSupported(context);
        }

        protected virtual bool OnIsEnabledAndSupported(GonbestEffectContext context)
        {
            return enabled;
        }

        protected abstract Type OnPostRendererType();

    }
}
