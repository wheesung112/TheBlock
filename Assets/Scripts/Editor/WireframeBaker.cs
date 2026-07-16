using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;

public class WireframeBaker : EditorWindow
{
    [MenuItem("Tools/Wireframe/Bake Mesh for Wireframe")]
    static void Init()
    {
        GetWindow<WireframeBaker>("Wireframe Baker");
    }

    private void OnGUI()
    {
        GUILayout.Label("Bake Mesh Data for Mobile Wireframe", EditorStyles.boldLabel);
        GUILayout.Space(10);
        GUILayout.Label("Selected objects: " + Selection.gameObjects.Length);
        
        if (GUILayout.Button("Bake Selected Meshes"))
        {
            BakeSelected();
        }
    }

    static void BakeSelected()
    {
        int processedCount = 0;
        foreach (var go in Selection.gameObjects)
        {
            // Collect all MeshFilters and SkinnedMeshRenderers (including children)
            List<Component> renderers = new List<Component>();
            renderers.AddRange(go.GetComponentsInChildren<MeshFilter>(true));
            renderers.AddRange(go.GetComponentsInChildren<SkinnedMeshRenderer>(true));

            if (renderers.Count == 0)
            {
                Debug.LogWarning($"[WireframeBaker] Skipped '{go.name}' - No MeshFilter or SkinnedMeshRenderer found in hierarchy.");
                continue;
            }

            foreach (var comp in renderers)
            {
                Mesh originalMesh = null;
                SkinnedMeshRenderer smr = comp as SkinnedMeshRenderer;
                MeshFilter mf = comp as MeshFilter;

                if (smr != null) originalMesh = smr.sharedMesh;
                else if (mf != null) originalMesh = mf.sharedMesh;

                if (originalMesh == null) continue;

                string path = AssetDatabase.GetAssetPath(originalMesh);
                // Fix: If path is empty (runtime mesh) OR not in Assets folder (Library/Built-in), force to BakedMeshes folder
                if (string.IsNullOrEmpty(path) || !path.StartsWith("Assets/"))
                {
                    path = "Assets/BakedMeshes/";
                    if (!Directory.Exists(path)) Directory.CreateDirectory(path);
                    path += originalMesh.name + "_Baked.asset";
                }
                else
                {
                    string dir = Path.GetDirectoryName(path);
                    string filename = Path.GetFileNameWithoutExtension(path);
                    
                    if (filename.EndsWith("_Wireframe"))
                    {
                        // Keep existing path
                    }
                    else
                    {
                        string meshName = originalMesh.name;
                        foreach(char c in Path.GetInvalidFileNameChars()) { meshName = meshName.Replace(c, '_'); }
                        path = dir + "/" + filename + "_" + meshName + "_Wireframe.asset";
                    }
                }

                // Process
                Mesh newMesh = ProcessMesh(originalMesh);
                AssetDatabase.CreateAsset(newMesh, path);
                
                // Assign
                if (smr != null) smr.sharedMesh = newMesh;
                else if (mf != null) mf.sharedMesh = newMesh;

                EditorUtility.SetDirty(comp.gameObject);
                Debug.Log($"[WireframeBaker] Baked: {path}");
                processedCount++;
            }
        }
        
        if (processedCount > 0) AssetDatabase.SaveAssets();
        else Debug.LogWarning("[WireframeBaker] No meshes were baked. Please select objects containing MeshFilters or SkinnedMeshRenderers.");
    }

    static Mesh ProcessMesh(Mesh source)
    {
        // 1. Get original data
        Vector3[] oldVerts = source.vertices;
        Vector3[] oldNormals = source.normals;
        Vector2[] oldUVs = source.uv;
        Vector4[] oldTangents = source.tangents;
        BoneWeight[] oldBoneWeights = source.boneWeights; // Skinned Mesh Support

        // 2. Prepare new data lists
        List<Vector3> newVerts = new List<Vector3>();
        List<Vector3> newNormals = new List<Vector3>();
        List<Vector2> newUVs = new List<Vector2>();
        List<Vector2> newUV2s = new List<Vector2>(); // Lightmap UVs
        List<Vector4> newTangents = new List<Vector4>();
        List<BoneWeight> newBoneWeights = new List<BoneWeight>(); // Skinned Mesh Support

        List<Vector4> newUV3 = new List<Vector4>(); // Barycentrics (w=1 flag)
        List<Vector4> newUV4 = new List<Vector4>(); // Centroids (w=1 flag)

        // Store new indices per submesh
        List<int>[] newSubmeshIndices = new List<int>[source.subMeshCount];
        int globalVertexIndex = 0;
        
        Vector2[] oldUV2s = source.uv2; // Cache original UV2

        // 3. Iterate over each submesh
        for (int sub = 0; sub < source.subMeshCount; sub++)
        {
            int[] oldIndices = source.GetTriangles(sub);
            newSubmeshIndices[sub] = new List<int>(oldIndices.Length);

            for (int i = 0; i < oldIndices.Length; i += 3)
            {
                int i0 = oldIndices[i];
                int i1 = oldIndices[i+1];
                int i2 = oldIndices[i+2];

                // Get original stats
                Vector3 v0 = oldVerts[i0];
                Vector3 v1 = oldVerts[i1];
                Vector3 v2 = oldVerts[i2];

                // Calculate Centroid
                Vector3 center = (v0 + v1 + v2) / 3.0f;
                // Use existing centroid logic (baked into UV8)
                Vector4 center4 = new Vector4(center.x, center.y, center.z, 1.0f);

                // Add Vertices (Split)
                newVerts.Add(v0);
                newVerts.Add(v1);
                newVerts.Add(v2);

                if (oldNormals.Length > 0)
                {
                    newNormals.Add(oldNormals[i0]);
                    newNormals.Add(oldNormals[i1]);
                    newNormals.Add(oldNormals[i2]);
                }

                if (oldUVs.Length > 0)
                {
                    newUVs.Add(oldUVs[i0]);
                    newUVs.Add(oldUVs[i1]);
                    newUVs.Add(oldUVs[i2]);
                }

                if (oldUV2s.Length > 0)
                {
                    newUV2s.Add(oldUV2s[i0]);
                    newUV2s.Add(oldUV2s[i1]);
                    newUV2s.Add(oldUV2s[i2]);
                }
                
                if (oldTangents.Length > 0)
                {
                    newTangents.Add(oldTangents[i0]);
                    newTangents.Add(oldTangents[i1]);
                    newTangents.Add(oldTangents[i2]);
                }

                if (oldBoneWeights.Length > 0)
                {
                    newBoneWeights.Add(oldBoneWeights[i0]);
                    newBoneWeights.Add(oldBoneWeights[i1]);
                    newBoneWeights.Add(oldBoneWeights[i2]);
                }

                // Barycentric Coords (w=1 flag)
                newUV3.Add(new Vector4(1, 0, 0, 1));
                newUV3.Add(new Vector4(0, 1, 0, 1));
                newUV3.Add(new Vector4(0, 0, 1, 1));
                
                // Centroids
                newUV4.Add(center4);
                newUV4.Add(center4);
                newUV4.Add(center4);
                
                // Add Indices for this submesh
                newSubmeshIndices[sub].Add(globalVertexIndex++);
                newSubmeshIndices[sub].Add(globalVertexIndex++);
                newSubmeshIndices[sub].Add(globalVertexIndex++);
            }
        }

        Mesh mesh = new Mesh();
        mesh.name = source.name + "_Wireframe";
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32; 

        mesh.SetVertices(newVerts);
        if (oldNormals.Length > 0) mesh.SetNormals(newNormals);
        if (oldUVs.Length > 0) mesh.SetUVs(0, newUVs);
        if (newUV2s.Count > 0) mesh.SetUVs(1, newUV2s); // Set UV2
        if (oldTangents.Length > 0) mesh.SetTangents(newTangents);
        if (newBoneWeights.Count > 0)
        {
            mesh.boneWeights = newBoneWeights.ToArray();
            mesh.bindposes = source.bindposes;
        }
        
        mesh.SetUVs(6, newUV3); // UV7
        mesh.SetUVs(7, newUV4); // UV8

        // Assign Submeshes
        mesh.subMeshCount = source.subMeshCount;
        for (int sub = 0; sub < source.subMeshCount; sub++)
        {
            mesh.SetTriangles(newSubmeshIndices[sub], sub);
        }
        
        mesh.RecalculateBounds();
        
        return mesh;
    }
}
