using UnityEngine;
using UnityEngine.SceneManagement;

public class PersistentCameraRig : MonoBehaviour
{
    public static PersistentCameraRig Instance;

    public Transform centerEyeAnchor;
    public Transform leftHandAnchor;
    public Transform rightHandAnchor;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
            SceneManager.sceneLoaded += OnSceneLoaded;
            
            // Auto-find anchors if OVRCameraRig structure is standard
            // Standard OVR Hierarchy: OVRCameraRig -> TrackingSpace -> ...Anchors
            Transform trackingSpace = transform.Find("TrackingSpace");
            if (trackingSpace != null)
            {
                centerEyeAnchor = trackingSpace.Find("CenterEyeAnchor");
                leftHandAnchor = trackingSpace.Find("LeftHandAnchor");
                rightHandAnchor = trackingSpace.Find("RightHandAnchor");
            }
        }
        else
        {
            Destroy(gameObject); 
        }
    }

    private void OnDestroy()
    {
        if (Instance == this)
        {
            SceneManager.sceneLoaded -= OnSceneLoaded;
        }
    }

    private void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        // Find Spawn Point
        PlayerSpawnPoint spawnPoint = FindObjectOfType<PlayerSpawnPoint>();
        if (spawnPoint != null)
        {
            // Teleport Rig
            transform.position = spawnPoint.transform.position;
            transform.rotation = spawnPoint.transform.rotation;
            
            // Optional: Reset camera tracking if needed, 
            // but usually moving the rig is enough for room-scale setups 
            // to place the center of the play area at the spawn point.
            Debug.Log($"[PersistentCameraRig] Teleported to {spawnPoint.name}");
        }
    }
}
