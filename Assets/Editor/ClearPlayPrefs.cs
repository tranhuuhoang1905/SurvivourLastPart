using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;

public class ClearPlayPrefs
{
    [MenuItem("Tools/PlayerPrefs/Clear All PlayerPrefs", false, 1000)]
    private static void ClearAllPrefs()
    {
        if (EditorUtility.DisplayDialog("Confirm", "Are you sure you want to delete all PlayerPrefs?", "Yes", "No"))
        {
            PlayerPrefs.DeleteAll();
            PlayerPrefs.Save();
            Debug.Log("------ All PlayerPrefs have been deleted! ------");
        }
    }
    
    [MenuItem("Tools/PlayerPrefs/Delete PlayerPrefs By Key", false, 1001)]
    private static void DeletePlayerPrefsByKey()
    {
        DeletePlayerPrefsWindow.ShowWindow();
    }
}

public class DeletePlayerPrefsWindow : EditorWindow
{
    private string keyToDelete = "";

    public static void ShowWindow()
    {
        GetWindow<DeletePlayerPrefsWindow>("Delete PlayerPrefs Key");
    }

    private void OnGUI()
    {
        GUILayout.Label("Enter the PlayerPrefs key to delete:", EditorStyles.boldLabel);
        keyToDelete = EditorGUILayout.TextField("Key:", keyToDelete);

        if (GUILayout.Button("Delete"))
        {
            if (!string.IsNullOrEmpty(keyToDelete))
            {
                if (PlayerPrefs.HasKey(keyToDelete))
                {
                    PlayerPrefs.DeleteKey(keyToDelete);
                    PlayerPrefs.Save();
                    Debug.Log($"------ PlayerPrefs Key '{keyToDelete}' has been deleted! ------");
                }
                else
                {
                    Debug.LogWarning($"------ PlayerPrefs Key '{keyToDelete}' does not exist! ------");
                }
            }
        }
    }
}
#endif