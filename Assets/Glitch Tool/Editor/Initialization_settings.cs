using UnityEngine;
using System.Collections;
using UnityEditor;

namespace Haipeng.glitch
{
    public static class Initialization_settings
    {
        [MenuItem("Tools/WuHaipeng/add layer")]
        public static void add_layer()
        {
            SerializedObject tagManager = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
            SerializedProperty layers = tagManager.FindProperty("layers");
            bool ExistLayer = false;

            for (int i = 8; i < layers.arraySize; i++)
            {
                SerializedProperty layerSP = layers.GetArrayElementAtIndex(i);

                if (layerSP.stringValue == "glitch_layer")
                {
                    ExistLayer = true;
                    break;
                }

            }
            for (int j = 8; j < layers.arraySize; j++)
            {
                SerializedProperty layerSP = layers.GetArrayElementAtIndex(j);
                if (layerSP.stringValue == "" && !ExistLayer)
                {
                    layerSP.stringValue = "glitch_layer";
                    tagManager.ApplyModifiedProperties();

                    break;
                }
            }

            Debug.Log("add layer successful");
        }
    }
}