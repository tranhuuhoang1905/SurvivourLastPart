using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
    public class BloomRenderer : GonbestEffectRenderer<BloomSetting>
    {
        //扩散层数的最大值
        private const int CONST_DIFFUSION_LAYER_MAX_COUNT = 6; 
        
        private List<RenderTexture> _dlist = new List<RenderTexture>();
        private List<RenderTexture> _ulist = new List<RenderTexture>();
        private Shader _bloomShader;

        protected override void OnInit()
        {
            _bloomShader = RuntimeUtilities.FindShader("Hidden/Ares/PostEffect/Bloom");
            base.OnInit();
        }

        protected override void OnRelease()
        {
            base.OnRelease();
        }


        protected override void OnRender(GonbestEffectContext context)
        {           

            var sheet = context.Sheets.Get(_bloomShader);

          
            // Do bloom on a half-res buffer, full-res doesn't bring much and kills performances on fillrate limited platforms
            int tw = Mathf.FloorToInt(context.ScreenWidth / 2f );
            int th = Mathf.FloorToInt(context.ScreenHeight / 2f);            

            // Determine the iteration count
            int s = Mathf.Max(tw, th);
            float logs = Mathf.Log(s, 2f) + Mathf.Min(settings.diffusion, 10f) - 10f;
            int logs_i = Mathf.FloorToInt(logs);
            int iterations = Mathf.Clamp(logs_i, 1, CONST_DIFFUSION_LAYER_MAX_COUNT);
            float sampleScale = 0.5f + logs - logs_i;
            sheet.material.SetFloat(ShaderIDs.SampleScale, sampleScale);

            // Prefiltering parameters
            float lthresh =  Mathf.GammaToLinearSpace(settings.threshold);
            float knee = lthresh * settings.softKnee + 1e-5f;
            var threshold = new Vector4(lthresh, lthresh - knee, knee * 2f, 0.25f / knee);
            sheet.material.SetVector(ShaderIDs.Threshold, threshold);

            float lclamp = Mathf.GammaToLinearSpace(settings.clamp);
            sheet.material.SetVector(ShaderIDs.Params, new Vector4(lclamp, 0f, 0f, 0f));

            _dlist.Clear();
            _ulist.Clear();
            var last = context.GetRT(tw, th);
            var up = context.GetRT(tw, th);           
            GonbestGraphics.Blit(context.Source, last, sheet.material, 1);
            _dlist.Add(last);
            _ulist.Add(up);
            for (int i = 1; i < iterations; i++)
            {

                tw = Mathf.Max(tw / 2, 1);
                th = Mathf.Max(th / 2, 1);

                var mipDown = context.GetRT(tw, th);
                var mipup = context.GetRT(tw, th);
                _dlist.Add(mipDown);
                _ulist.Add(mipup);
                GonbestGraphics.Blit(last, mipDown, sheet.material, 3);
                last = mipDown;
            }

            
            for (int i = iterations - 2; i >= 0; i--)
            {
                sheet.material.SetTexture(ShaderIDs.BloomTex, _dlist[i]);
                GonbestGraphics.Blit(last, _ulist[i], sheet.material, 5);
                last = _ulist[i];
            } 

            _dlist.Clear();
            _ulist.Clear();
             
            context.LockRT(last);
            context.ReleaseWithUnlockRTs();

            
            var linearColor = settings.color.linear;
            float intensity = RuntimeUtilities.Exp2(settings.intensity / 10f) - 1f;
            var shaderSettings = new Vector4(sampleScale, intensity, 1, iterations);
         
             
            // Shader properties
            var uberSheet = context.UberSheet;
            uberSheet.EnableKeyword("_GONBEST_BLOOM_ON");
            uberSheet.material.SetVector(ShaderIDs.Bloom_Settings, shaderSettings);
            uberSheet.material.SetColor(ShaderIDs.Bloom_Color, linearColor);
            uberSheet.material.SetTexture(ShaderIDs.BloomTex, last);
            
        }
    }
}
