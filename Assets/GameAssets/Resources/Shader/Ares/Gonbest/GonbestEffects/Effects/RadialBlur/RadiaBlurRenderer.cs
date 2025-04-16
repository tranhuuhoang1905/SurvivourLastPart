using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
    /// <summary>
    /// 径向模糊处理
    /// </summary>
    public class RadiaBlurRenderer : GonbestEffectRenderer<RadiaBlurSetting>
    {
        private Shader _RadiaBlurShader;

        protected override void OnInit()
        {
            _RadiaBlurShader = RuntimeUtilities.FindShader("Hidden/Ares/PostEffect/RadiaBlur");
            base.OnInit();
        }

        protected override void OnRelease()
        {
            base.OnRelease();
        }


        protected override GonbestEffectTypeCode OnGetEffectType()
        {
            return GonbestEffectTypeCode.ChangedEffect;
        }

        protected override void OnRender(GonbestEffectContext context)
        {
            int tw = Mathf.FloorToInt(context.ScreenWidth / 2f);
            int th = Mathf.FloorToInt(context.ScreenHeight / 2f);
            var rt = context.GetRT(tw,th);

            var sheet = context.Sheets.Get(_RadiaBlurShader);
            sheet.material.SetVector(ShaderIDs.CenterAndStrength,new Vector4(settings.CenterX, settings.CenterY, settings.ForceX, settings.ForceY));
            GonbestGraphics.Blit(context.Source, rt, sheet.material, 0);
            context.LockRT(rt);
            context.ReleaseWithUnlockRTs();
            context.Source = rt;
        }
    }
}
