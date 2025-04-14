using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Thousandto.Launcher.ExternalLibs
{
    /// <summary>
    /// 仿Graphics的Blit处理
    /// </summary>
    public class GonbestGraphics
    {
        //默认材质
        public static Shader DefaultShader;
        //MainTex的属性ID
        private static int _MainTexID;
        //全屏的面片
        private static Mesh _fullscreenQuadMesh;

        private static Material _defaultMaterial;
        public static Material DefaultMaterial
        {
            get
            {
                if (_defaultMaterial == null)
                {
                    _defaultMaterial = CrateDefaultMaterial();
                }
                return _defaultMaterial;
            }
        }

        //构造函数
        static GonbestGraphics()
        {
            _fullscreenQuadMesh = CreateScreenSpaceQuadMesh();
            _MainTexID = Shader.PropertyToID("_MainTex");
        }

        //仿Graphics的Blit处理
        public static void Blit(Texture source, RenderTexture destination, Material material , int materialPass = 0, bool clear = false)
        {
            SetActiveRenderTextureAndClear(destination, clear);
            DrawFullscreenQuad(source, material, materialPass);
        }

        //清屏处理
        public static void Clear()
        {
            GL.Clear(true, true, new Color(1f, 0.75f, 0.5f, 0.8f));
        }

        private static void DrawFullscreenQuad(Texture source, Material material, int materialPass = 0)
        { 
            material.SetTexture(_MainTexID, source);
            material.SetPass(materialPass);
            Graphics.DrawMeshNow(_fullscreenQuadMesh, Matrix4x4.identity);
        }

        private static void SetActiveRenderTextureAndClear(RenderTexture destination, bool clear = true)
        {
            Graphics.SetRenderTarget(destination);
            if (clear)
            {
                Clear();
            }
        }

        //创建默认材质
        private static Material CrateDefaultMaterial()
        {
            if (DefaultShader == null)
            {
                DefaultShader = Shader.Find("Hidden/Ares/PostEffect/Uber");
            }
            if (DefaultShader != null)
            {
                var mat = new Material(DefaultShader);
                mat.hideFlags = HideFlags.DontSave;
                return mat;
            }
            else
            {
                Debug.LogError("Shader not found:Hidden/Ares/PostEffect/Default,Cannot use default materials");
            }
            return null;
        }

        //创建一个全屏的面片
        private static Mesh CreateScreenSpaceQuadMesh()
        {
            Mesh mesh = new Mesh();
            mesh.hideFlags = HideFlags.DontSave;
            Vector3[] vertices = new Vector3[]
            {
                new Vector3(-1f, -1f, 0f),
                new Vector3(-1f, 1f, 0f),
                new Vector3(1f, 1f, 0f),
                new Vector3(1f, -1f, 0f)
            };
            Vector2[] uv = new Vector2[]
            {
                new Vector2(0f, 0f),
                new Vector2(0f, 1f),
                new Vector2(1f, 1f),
                new Vector2(1f, 0f)
            };
            Color[] colors = new Color[]
            {
                new Color(0f, 0f, 1f),
                new Color(0f, 1f, 1f),
                new Color(1f, 1f, 1f),
                new Color(1f, 0f, 1f)
            };
            int[] triangles = new int[]
            {
                0,
                2,
                1,
                0,
                3,
                2
            };
            mesh.vertices = vertices;
            mesh.uv = uv;
            mesh.triangles = triangles;
            mesh.colors = colors;
            mesh.UploadMeshData(true);
            
            return mesh;
        }
    }
}
