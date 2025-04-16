using UnityEngine;
using UnityObject = UnityEngine.Object;

namespace Thousandto.Launcher.ExternalLibs
{
    public class RuntimeUtilities
    {

        /// <summary>
        /// Returns the base-2 exponential function of <paramref name="x"/>, which is <c>2</c>
        /// raised to the power <paramref name="x"/>.
        /// </summary>
        /// <param name="x">Value of the exponent</param>
        /// <returns>The base-2 exponential function of <paramref name="x"/></returns>
        public static float Exp2(float x)
        {
            return Mathf.Exp(x * 0.69314718055994530941723212145818f);
        }


        /// <summary>
        /// Properly destroys a given Unity object.
        /// </summary>
        /// <param name="obj">The object to destroy</param>
        public static void Destroy(UnityObject obj)
        {
            if (obj != null)
            {
#if UNITY_EDITOR
                if (Application.isPlaying)
                    UnityObject.Destroy(obj);
                else
                    UnityObject.DestroyImmediate(obj);
#else
                UnityObject.Destroy(obj);
#endif
            }
        }

        /// <summary>
        ///查找Shader
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static Shader FindShader(string name)
        {
#if FUNCELL_LAUNCHER
            return ShaderFactory.Find(name);
#else
            return Shader.Find(name);
#endif
        }
    }
}
