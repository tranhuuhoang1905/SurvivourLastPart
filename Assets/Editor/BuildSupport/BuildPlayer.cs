using System;
using System.IO;
using GameNatra;
using UnityEditor;
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;

public static class BuildPlayer
{
    private const string OutputPathStreamingAssets = "StreamingAssets/bb";
    private const string SplashScenePath = "Assets/GameNatra/Scenes/Splash.unity";
    private const string applicationIdentifier = "jp.bap.game.nezhademondash";

    // Increase the version numbers for the build
    private static void IncreaseVersionNumbers()
    {
        PlayerSettings.bundleVersion = IncreaseVersion(PlayerSettings.bundleVersion);
        PlayerSettings.Android.bundleVersionCode++;
        PlayerSettings.iOS.buildNumber = IncreaseVersion(PlayerSettings.iOS.buildNumber);
    }

    // Increase the version number by incrementing the last part
    private static string IncreaseVersion(string version)
    {
        string[] parts = version.Split('.');
        int lastPart = int.Parse(parts[parts.Length - 1]);
        lastPart++;
        parts[parts.Length - 1] = lastPart.ToString();
        return string.Join(".", parts);
    }

    // Clear the build folder
    private static void ClearBuildFolder(string folderPath)
    {
        if (Directory.Exists(folderPath))
        {
            Directory.Delete(folderPath, true);
        }
    }

    // Show the output folder in the file explorer
    private static void ShowOutputFolder(string outputPath)
    {
#if UNITY_EDITOR_WIN
        EditorUtility.RevealInFinder(outputPath);
#elif UNITY_EDITOR_OSX
        EditorUtility.RevealInFinder(outputPath);
#endif
    }

    // Copy the contents of one directory to another
    private static void CopyDirectory(string sourceDir, string destDir)
    {
        if (!Directory.Exists(destDir))
        {
            Directory.CreateDirectory(destDir);
        }

        string[] files = Directory.GetFiles(sourceDir);
        foreach (string file in files)
        {
            string fileName = Path.GetFileName(file);
            string destFile = Path.Combine(destDir, fileName);
            File.Copy(file, destFile, true);
        }

        string[] dirs = Directory.GetDirectories(sourceDir);
        foreach (string dir in dirs)
        {
            string dirName = Path.GetFileName(dir);
            string destSubDir = Path.Combine(destDir, dirName);
            CopyDirectory(dir, destSubDir);
        }
    }

    // Get the build path for addressable assets
    private static string GetBuildPathAddressable()
    {
        AddressableAssetSettings settings = AddressableAssetSettingsDefaultObject.Settings;
        string buildPath = "";
        if (settings.BuildRemoteCatalog)
        {
            buildPath = settings.RemoteCatalogBuildPath.GetValue(settings);
            ClearBuildFolder(buildPath);
        }

        return buildPath;
    }

    // Build the project for WebGL
    private static void BuildWeb(string outputPath, BuildTarget target, BuildOptions options = BuildOptions.None)
    {
        string[] scenes = {
            SplashScenePath,
        };

        PlayerSettings.SplashScreen.show = false;

        BuildPipeline.BuildPlayer(scenes, outputPath, target, options);
    }

    // Build the project for mobile platforms (Android/iOS)
    private static void BuildMobile(string outputPath, BuildTarget target, BuildTargetGroup targetGroup, BuildOptions options = BuildOptions.None | BuildOptions.CompressWithLz4HC)
    {
        string[] scenes = {
            SplashScenePath,
        };

        PlayerSettings.SplashScreen.show = false;

        BuildPlayerOptions buildOptions = new()
        {
            scenes = scenes,
            locationPathName = outputPath,
            target = target,
            options = options
        };

        BuildPipeline.BuildPlayer(buildOptions);
    }

    // Perform the build process
    private static void PerformBuild(BuildTarget target, BuildTargetGroup targetGroup = BuildTargetGroup.WebGL, BuildOptions options = BuildOptions.None)
    {
        //string outputPath = networkMode == NetworkManager.Mode.LOCAL ? EditorUtility.SaveFolderPanel("Select Output Folder", "", "") : GetOutputPath(networkMode, target);
        string outputPath = GetOutputPath(target);

        if (string.IsNullOrEmpty(outputPath))
            return;

        ClearBuildFolder(outputPath);
        IncreaseVersionNumbers();

        if (targetGroup == BuildTargetGroup.WebGL)
        {
            BuildWeb(outputPath, target);
            CopyDirectory("ServerData/WebGL", Path.Combine(outputPath, OutputPathStreamingAssets, target.ToString()));
        }
        else if (targetGroup == BuildTargetGroup.Android)
        {
            BuildMobile(outputPath, target, targetGroup, BuildOptions.Development);
        }

        ShowOutputFolder(outputPath);
    }

    // Get the output path for the build
    private static string GetOutputPath(BuildTarget target)
    {
        string outputPath = $"Build/{target}/GameNatra";

        return outputPath;
    }

    // Menu item to build WebGL for local environment
    [MenuItem("Build Tools/Build WebGL/LOCAL")]
    public static void AutoBuildWebGL_LOCAL()
    {
        BuildAddressable.BuildManual(BuildTargetGroup.WebGL, BuildTarget.WebGL, "Build-in");

        BuildTarget target = BuildTarget.WebGL;
        string outputPath = GetOutputPath(target);
        BuildWeb(outputPath, target);
        ShowOutputFolder(outputPath);
    }

    // Menu item to build Android for local environment
    [MenuItem("Build Tools/Build Android/LOCAL")]
    public static void AutoBuildAndroid_LOCAL()
    {
        VersionInputDialog.onVersionEntered = (version, buildNumber) =>
        {
            SetApplicationIdentifiers();
            BuildAddressable.BuildManual(BuildTargetGroup.Android, BuildTarget.Android, "Build-in");
            PerformAndroidBuild(version, buildNumber, ".apk");
        };
        EditorWindow.GetWindow(typeof(VersionInputDialog));
    }

    // Menu item to build iOS for local environment
    [MenuItem("Build Tools/Build iOS/LOCAL")]
    public static void AutoBuildIOS_LOCAL()
    {
        VersionInputDialog.onVersionEntered = (version, buildNumber) =>
        {
            SetApplicationIdentifiers();
            BuildAddressable.BuildManual(BuildTargetGroup.iOS, BuildTarget.iOS, "Build-in");
            PerformAndroidBuild(version, buildNumber, null, BuildTarget.iOS, BuildTargetGroup.iOS);
        };
        EditorWindow.GetWindow(typeof(VersionInputDialog));
    }

    // Set the application identifiers for the build
    private static void SetApplicationIdentifiers()
    {
        PlayerSettings.applicationIdentifier = applicationIdentifier;
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, applicationIdentifier);
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.iOS, applicationIdentifier);
    }

    // Perform the Android build process
    private static void PerformAndroidBuild(string version, string buildNumber, string extension, BuildTarget target = BuildTarget.Android, BuildTargetGroup buildTarget = BuildTargetGroup.Android)
    {
        if (!string.IsNullOrEmpty(version))
        {
            PlayerSettings.bundleVersion = version;
        }

        if (!string.IsNullOrEmpty(buildNumber))
        {
#if UNITY_ANDROID
            PlayerSettings.Android.bundleVersionCode = int.Parse(buildNumber);            
#elif UNITY_IOS
            PlayerSettings.iOS.buildNumber = buildNumber;
#endif
        }

        // Save the changes to the PlayerSettings
        AssetDatabase.SaveAssets();
        string outputPath = GetOutputPath(target) + extension;
        BuildMobile(outputPath, target, buildTarget);
        ShowOutputFolder(outputPath);
    }
}