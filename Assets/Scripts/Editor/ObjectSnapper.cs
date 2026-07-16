using UnityEngine;
using UnityEditor;

public class ObjectSnapper : EditorWindow
{
    [MenuItem("Tools/Level Design/Snap Selected to Ground %g")] // Ctrl+G shortcut
    public static void SnapToGround()
    {
        GameObject[] selectedObjects = Selection.gameObjects;
        if (selectedObjects.Length == 0)
        {
            Debug.LogWarning("No objects selected to snap.");
            return;
        }

        Undo.RecordObjects(selectedObjects, "Snap to Ground");

        int matchCount = 0;
        foreach (GameObject go in selectedObjects)
        {
            // Raycast down from the object + a bit of offset to avoid self-collision if pivot is weird
            // Also supports snapping FROM below if we want, but usually "Drop" implies down.
            // Let's start ray from a bit high up if the pivot is low, or just use pivot.
            // Safest: Raycast from the object's position downwards.
            
            // To be robust: If object is UNDER terrain, maybe we want to raycast UP too? 
            // User said "put in air and detect Y axis". So Downward is primary.

            Ray ray = new Ray(go.transform.position + Vector3.up * 10f, Vector3.down); // Start 10 units up just in case pivot is buried? 
            // Better: Start exactly at transform, but exclude itself.
            // Actually, best for "Drop" is simple Physics.Raycast(go.transform.position, Vector3.down)
            
            RaycastHit hit;
            // Use a mask if needed, but 'Expected everything static is ground' usually holds.
            if (Physics.Raycast(go.transform.position, Vector3.down, out hit, Mathf.Infinity))
            {
                go.transform.position = hit.point;
                matchCount++;
            }
            else
            {
                // Try finding active terrain height directly if Raycast fails (e.g. no collider on terrain?)
                Terrain terrain = Terrain.activeTerrain;
                if (terrain != null)
                {
                    float y = terrain.SampleHeight(go.transform.position) + terrain.transform.position.y;
                    Vector3 pos = go.transform.position;
                    pos.y = y;
                    go.transform.position = pos;
                    matchCount++;
                }
            }
        }
        
        Debug.Log($"Snapped {matchCount} objects to ground.");
    }
}
