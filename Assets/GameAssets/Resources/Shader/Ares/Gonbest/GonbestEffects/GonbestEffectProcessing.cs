using System.Collections.Generic;
using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
#if UNITY_2018_3_OR_NEWER
    [ExecuteAlways]
#else
    [ExecuteInEditMode]
#endif
    public class GonbestEffectProcessing:MonoBehaviour
    {
        //效果的渲染处理
        private GonbestEffectBundleRenderer _renderers = new GonbestEffectBundleRenderer();
        //效果的上下文
        private GonbestEffectContext _context = new GonbestEffectContext();
        //材质属性
        private PropertySheetFactory _sheets = new PropertySheetFactory();

        //后处理设置数据的存储
        public List<GonbestEffectSetting> Settings = new List<GonbestEffectSetting>();      

        private void SetupContext()
        {
            _context.Release();
            _context.Camera = GetComponent<Camera>();
            _context.Sheets = _sheets;
        }

        private void OnEnable()
        {
            SetupContext();
            _renderers.Intialize(Settings);
        }
        
        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {

            _context.Source = source;
            _context.Destination = destination;
            _context.UberSheet.ClearKeywords();
            Shader.SetGlobalFloat(ShaderIDs.RenderViewportScaleFactor, 1f);
            _renderers.Render(_context);
            ApplyFlip(_context);

            var dest = _context.Destination;
#if UNITY_EDITOR
            RenderTexture rt = _context.GetRT();
            dest = rt;
#endif
            _context.UberSheet.EnableKeyword("_GONBEST_GRAPHIC_BLIT_ON");
            GonbestGraphics.Blit(_context.Source, dest, _context.UberSheet.material);

#if UNITY_EDITOR
            dest = _context.Destination;
            Graphics.Blit(rt, dest);
#endif
            _context.ReleaseAllRTs();
        }

        private void OnValidate()
        {
            SetupContext();
            _renderers.Intialize(Settings);
        }

        void ApplyFlip(GonbestEffectContext context)
        {
            if (context.Flip && !context.IsSceneView)
                context.UberSheet.material.SetVector(ShaderIDs.UVTransform, new Vector4(1.0f, 1.0f, 0.0f, 0.0f));
            else
                ApplyDefaultFlip(context.UberSheet);
        }

        void ApplyDefaultFlip(PropertySheet sheet)
        {
            sheet.material.SetVector(ShaderIDs.UVTransform, SystemInfo.graphicsUVStartsAtTop ? new Vector4(1.0f, -1.0f, 0.0f, 1.0f) : new Vector4(1.0f, 1.0f, 0.0f, 0.0f));
        }

        private void OnDisable()
        {
            _context.Release();
        }

        private void OnDestroy()
        {
            _renderers.Release();
            _sheets.Release();
            _context.Release();
        }


    }
}
