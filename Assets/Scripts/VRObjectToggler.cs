using UnityEngine;

public class VRObjectToggler : MonoBehaviour
{
    [Header("Interaction Settings")]
    [Tooltip("Distance to accept interaction")]
    public float interactionDistance = 5.0f;
    [Tooltip("If true, this object itself must be clicked. If false, clicking anywhere triggers it (Global input).")]
    public bool requireRaycastHit = true;

    [Header("Targets")]
    [Tooltip("List of objects to toggle Active/Inactive")]
    public GameObject[] toggleObjects;

    private void Update()
    {
        if (PersistentCameraRig.Instance == null) return;

        // Check Inputs (Index or Hand Trigger)
        bool leftClick = OVRInput.GetDown(OVRInput.Button.PrimaryIndexTrigger) || OVRInput.GetDown(OVRInput.Button.PrimaryHandTrigger);
        bool rightClick = OVRInput.GetDown(OVRInput.Button.SecondaryIndexTrigger) || OVRInput.GetDown(OVRInput.Button.SecondaryHandTrigger);

        if (leftClick || rightClick)
        {
            if (requireRaycastHit)
            {
                // Perform Raycast
                bool hit = false;
                if (leftClick && PersistentCameraRig.Instance.leftHandAnchor != null)
                    if (CheckRaycast(PersistentCameraRig.Instance.leftHandAnchor)) hit = true;
                
                if (!hit && rightClick && PersistentCameraRig.Instance.rightHandAnchor != null)
                    if (CheckRaycast(PersistentCameraRig.Instance.rightHandAnchor)) hit = true;

                if (hit) Toggle();
            }
            else
            {
                // Global Trigger (Any click toggles)
                Toggle();
            }
        }
    }

    private bool CheckRaycast(Transform origin)
    {
        Ray ray = new Ray(origin.position, origin.forward);
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit, interactionDistance))
        {
            // Check if we hit THIS object's collider
            if (hit.collider.gameObject == gameObject)
            {
                return true;
            }
        }
        return false;
    }

    public void Toggle()
    {
        foreach (var obj in toggleObjects)
        {
            if (obj != null)
            {
                bool newState = !obj.activeSelf;
                obj.SetActive(newState);
                // Optional: Play sound or feedback here
            }
        }
        Debug.Log($"[VRObjectToggler] Toggled {toggleObjects.Length} objects.");
    }
}
