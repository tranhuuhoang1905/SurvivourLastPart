using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Thousandto.Launcher.ExternalLibs
{
    /// <summary>
    /// 一个效果的Bundle
    /// </summary>
    public class GonbestEffectBundle
    {
        private GonbestEffectSetting _setting = null;
        private GonbestEffectRenderer _renderer = null;
        public GonbestEffectRenderer Renderer {
            get
            {
                if (_renderer == null && _setting != null)
                {
                    var type = _setting.PostRendererType();
                    _renderer = Activator.CreateInstance(type) as GonbestEffectRenderer;
                    _renderer.SetSettings(_setting);
                    _renderer.Init();
                }
                return _renderer;
            }

        }

        public GonbestEffectBundle(GonbestEffectSetting setting)
        {
            _setting = setting;
        }

        public void Release()
        {
            if (_renderer != null)
                _renderer.Release();
        }

    }
}
