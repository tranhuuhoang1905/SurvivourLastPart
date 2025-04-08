using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;
using UnityEngine;

public static class CheckDuplicateAddresses
{
    [MenuItem("Assets/GameTemplate/Check Duplicate Addresses")]
    private static void CheckAddresses()
    {
        var addressableEntries = AddressableAssetSettingsDefaultObject.Settings.groups
            .SelectMany(group => group.entries);

        var addressDictionary = new Dictionary<string, List<AddressableAssetEntry>>();

        foreach (var entry in addressableEntries)
        {
            if (addressDictionary.ContainsKey(entry.address))
            {
                addressDictionary[entry.address].Add(entry);
            }
            else
            {
                addressDictionary[entry.address] = new List<AddressableAssetEntry> { entry };
            }
        }

        foreach (var kvp in addressDictionary)
        {
            if (kvp.Value.Count > 1)
            {
                Debug.LogWarning($"Duplicate address found: {kvp.Key}");
                foreach (var entry in kvp.Value)
                {
                    Debug.LogWarning($" - Group: {entry.parentGroup.Name}, Asset: {entry.AssetPath}");
                }
            }
        }
    }
}