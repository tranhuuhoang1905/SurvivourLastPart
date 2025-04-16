using System.Collections.Generic;

namespace Thousandto.Launcher.ExternalLibs
{
    /// <summary>
    /// 后处理效果的渲染处理
    /// </summary>
    public class GonbestEffectBundleRenderer
    {
        private List<GonbestEffectBundle> _bundles = new List<GonbestEffectBundle>();

        public void Intialize(List<GonbestEffectSetting> settingList)
        {
            if (settingList != null)
            {
                Release();
                for (int i = 0; i < settingList.Count; i++)
                {
                    if (settingList[i] != null)
                    {
                        _bundles.Add(new GonbestEffectBundle(settingList[i]));
                    }
                }
                _bundles.Sort(OnSortFunc);
            }
        }

        public int Count {
            get {
                return _bundles.Count;
            }
        }

        public void Release()
        {
            for (int i = 0; i < _bundles.Count; i++)
            {
                _bundles[i].Release();
            }
            _bundles.Clear();
        }

        public void Render(GonbestEffectContext context)
        {
            for (int i = 0; i < _bundles.Count; i++)
            {
                _bundles[i].Renderer.Render(context);
            }
        }

        private int OnSortFunc(GonbestEffectBundle x, GonbestEffectBundle y)
        {
            //把改变Source的效果放在前面
            return y.Renderer.EffectType - x.Renderer.EffectType  ;
        }
    }
}
