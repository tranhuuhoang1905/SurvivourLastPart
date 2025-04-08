using System.IO;
using UnityEditor;
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;

public static class BuildAddressable
{
    private static void ClearBuildFolder(string folderPath)
    {
        if (Directory.Exists(folderPath))
        {
            Directory.Delete(folderPath, true);
        }
    }

    private static void ShowOutputFolder(string outputPath)
    {
#if UNITY_EDITOR_WIN
        EditorUtility.RevealInFinder(outputPath);
#else
        EditorUtility.RevealInFinder(outputPath.Replace("/", "\\"));
#endif
    }

    private static void BuildProfile(string profileName, BuildTargetGroup buildGroup, BuildTarget buildTarget)
    {
        AddressableAssetSettings settings = AddressableAssetSettingsDefaultObject.Settings;
        string buildPath = "";

        if (settings.BuildRemoteCatalog)
        {
            buildPath = settings.RemoteCatalogBuildPath.GetValue(settings);
            ClearBuildFolder(buildPath);
        }

        EditorUserBuildSettings.SwitchActiveBuildTarget(buildGroup, buildTarget);
        AddressableAssetSettingsDefaultObject.Settings.activeProfileId = AddressableAssetSettingsDefaultObject.Settings.profileSettings.GetProfileId(profileName);
        AddressableAssetSettings.CleanPlayerContent();
        AddressableAssetSettings.BuildPlayerContent();
    }

    public static void BuildManual(BuildTargetGroup targetGroup = BuildTargetGroup.Android, BuildTarget buildTarget = BuildTarget.Android, string profileName = "Build-in")
    {
        BuildProfile(profileName, targetGroup, buildTarget);
    }

    public static void BuildAndroidLocal()
    {
        BuildManual(BuildTargetGroup.Android, BuildTarget.Android, "Build-in");
    }
}