namespace Thousandto.Launcher.ExternalLibs
{
    /// <summary>
    /// 渲染处理
    /// </summary>
    public abstract class GonbestEffectRenderer
    {
        public GonbestEffectTypeCode EffectType
        {
            get {
                return OnGetEffectType();
            }
        }
        public void Init()
        {
            OnInit();
        }

        public void Render(GonbestEffectContext context)
        {
            if (!IsEnabledAndSupported(context)) return;
            OnRender(context);
        }

        public void Release()
        {
            OnRelease();
        }

       
     
        protected virtual void OnInit()
        {

        }

        protected virtual void OnRender(GonbestEffectContext context)
        {

        }

        protected virtual void OnRelease()
        {

        }

        protected virtual GonbestEffectTypeCode OnGetEffectType()
        {
            return GonbestEffectTypeCode.CoverEffect;
        }

        /// <inheritdoc />
        protected virtual bool IsEnabledAndSupported(GonbestEffectContext context)
        {
            return true;
        }

        internal abstract void SetSettings(GonbestEffectSetting settings);
    }

    public class GonbestEffectRenderer<T> : GonbestEffectRenderer
        where T: GonbestEffectSetting
    {
        /// The current state of the effect settings associated with this renderer.
        /// </summary>
        public T settings { get; internal set; }

        internal override void SetSettings(GonbestEffectSetting settings)
        {
            this.settings = (T)settings;
        }

        protected override bool IsEnabledAndSupported(GonbestEffectContext context)
        {
            if (this.settings != null)
            {
                return this.settings.IsEnabledAndSupported(context);
            }
            else {
                return false;
            }
        }
    }
}
