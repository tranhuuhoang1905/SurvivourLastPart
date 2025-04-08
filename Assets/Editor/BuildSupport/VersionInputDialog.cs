using System;
using UnityEditor;
using UnityEngine;

namespace GameNatra
{
    public class VersionInputDialog : EditorWindow
    {
        public static Action<string, string> onVersionEntered;
        private string version = "";
        private string buildNumber = "";

        private void OnGUI()
        {
            GUILayout.Label("Enter Editor Version", EditorStyles.boldLabel);
            
            // user input version and build number
            version = EditorGUILayout.TextField("Version", version);
            buildNumber = EditorGUILayout.TextField("Build Number", buildNumber);

            if (GUILayout.Button("OK"))
            {
                if (string.IsNullOrEmpty(version))
                {
                    ShowError("Please enter a version.");
                    return;
                }

                if (string.IsNullOrEmpty(buildNumber))
                {
                    ShowError("Please enter a build number.");
                    return;
                }

                onVersionEntered?.Invoke(version, buildNumber);
                CloseWindow();
            }
        }
        private void ShowError(string message)
        {
            EditorUtility.DisplayDialog("Error", message, "OK");
        }

        private void CloseWindow()
        {
            Close();
        }
    }
}