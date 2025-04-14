using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
    /// <summary>
    /// 效果处理
    /// </summary>
    public class GonbestEffectContext
    {
        #region//私有变量
        //渲染材质的属性页工厂
        private PropertySheetFactory _sheets;         
        //摄像机
        private Camera _camera;
        //渲染材质的属性页
        private PropertySheet _uberSheet;
        //屏幕宽度
        private int _screenWidth;
        //屏幕高度
        private int _screenHeight;
        //源对象
        private RenderTexture _source;
        //目标对象
        private RenderTexture _destination;
        //是否是场景视图
        private bool _isSceneView = false;

        //当前RenderTexture的格式
        private RenderTextureFormat _rtformat = RenderTextureFormat.Default;

        //当前Rendertexture的是否锁定的字典
        private Dictionary<RenderTexture, bool> _rtLockDict = new Dictionary<RenderTexture, bool>();
        //临时的需要被删除的RendererTexture
        private List<RenderTexture> _rtRemoveList = new List<RenderTexture>();
        #endregion

        public RenderTexture Source { get { return _source; } set { _source = value; } }
        public RenderTexture Destination { get { return _destination; } set { _destination = value; } }
        public bool Flip { get; set; }
        public int ScreenWidth { get { return _screenWidth; } }
        public int ScreenHeight { get { return _screenHeight; } }
        public RenderTextureFormat RTFormat { get { return _rtformat; } }
        public PropertySheet UberSheet { get { return _uberSheet; } }
        public bool IsSceneView { get { return _isSceneView; } }

        public Camera Camera {
            get { return _camera; }
            set {
                if (_camera != value)
                {
                    _camera = value;
                    _rtformat = _camera.allowHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default;
                    _screenWidth = _camera.pixelWidth;
                    _screenHeight = _camera.pixelHeight;
                    _isSceneView = _camera.cameraType == CameraType.SceneView;
                }
            }
        }
        public PropertySheetFactory Sheets {
            get { return _sheets; }
            set {
                if (_sheets != value)
                {
                    _sheets = value;
                    _uberSheet = _sheets.Get(RuntimeUtilities.FindShader("Hidden/Ares/PostEffect/Uber"));
                }
            }
        }


        public void Release()
        {
            ReleaseAllRTs();
        }

        public RenderTexture GetRT(int w = -1,int h = -1, FilterMode filter = FilterMode.Bilinear)
        {
            w = w <= 0 ? _screenWidth : w;
            h = h <= 0 ? _screenHeight : h;
            var rt = RenderTexture.GetTemporary(w, h,0, _rtformat, RenderTextureReadWrite.Default);
            rt.filterMode = filter;
            rt.wrapMode = TextureWrapMode.Clamp;
            rt.name = "GonbestEffectContext";
            _rtLockDict.Add(rt,false);
            return rt;
        }

        public void ReleaseRT(RenderTexture rt)
        {
            if (_rtLockDict.ContainsKey(rt))
            {
                RenderTexture.ReleaseTemporary(rt);
                _rtLockDict.Remove(rt);
                rt = null;
            }
        }

        public void LockRT(RenderTexture rt)
        {
            if (_rtLockDict.ContainsKey(rt))
            {
                _rtLockDict[rt] = true;
            }
        }

        public void UnLockRT(RenderTexture rt)
        {
            if (_rtLockDict.ContainsKey(rt))
            {
                _rtLockDict[rt] = false;
            }
        }

        public void ReleaseAllRTs()
        {
            var e = _rtLockDict.GetEnumerator();
            while (e.MoveNext())
            {
                RenderTexture.ReleaseTemporary(e.Current.Key);
            }
            e.Dispose();
            _rtLockDict.Clear();
        }

        public void ReleaseWithUnlockRTs()
        {
            _rtRemoveList.Clear();
            var e = _rtLockDict.GetEnumerator();
            while (e.MoveNext())
            {
                if (!e.Current.Value)
                {
                    _rtRemoveList.Add(e.Current.Key);
                }
            }
            e.Dispose();

            for (int i = 0; i < _rtRemoveList.Count; i++)
            {
                var rt = _rtRemoveList[i];
                _rtLockDict.Remove(rt);
                RenderTexture.ReleaseTemporary(rt);
            }
            _rtRemoveList.Clear();

        }

    }
}
