using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class FilmCutManager : MonoBehaviour
{
    [System.Serializable]
    public struct CutEvent
    {
        public string name; // For Label in Inspector
        public float triggerTime; // Seconds from start
        public GameObject targetObject;
        public bool setActive; // true = ON, false = OFF
    }

    [Header("Scene Settings")]
    public float cutDuration = 10.0f; // Total time before moving to next scene
    public string nextSceneName;
    public bool loopScene = false; // If true, reload current scene

    [Header("Transition Settings")]
    public bool fadeInOnStart = true;
    public float fadeInDuration = 2.0f;
    public float fadeOutDuration = 2.0f; // Used when changing scene

    [Header("Interaction (Skip/Next)")]
    public bool enableInteraction = false;
    public GameObject interactionTarget;
    public float interactionDistance = 10.0f;

    [Header("Sequenced Events")]
    public List<CutEvent> events = new List<CutEvent>();

    [Header("End Sequence Effects")]
    public bool enableGlitchShake = false;
    public float glitchIntensity = 0.5f;
    
    public bool enableFovZoom = false;
    public float targetFov = 60.0f;

    private void Start()
    {
        // 1. Initial Fade In
        if (fadeInOnStart && SceneFader.Instance != null)
        {
            // Fix: Force Alpha to 1 (Black) first, so we can fade to 0.
            // Otherwise default is 0, fading to 0 does nothing.
            SceneFader.Instance.SetAlpha(1.0f);
            SceneFader.Instance.FadeIn(fadeInDuration);
        }

        // 2. Start Sequence
        StartCoroutine(RunSequence());
    }

    private IEnumerator RunSequence()
    {
        float timer = 0f;
        List<int> triggeredIndices = new List<int>();
        bool skipped = false;

        // 1. Run Main Cut Sequence
        while (timer < cutDuration)
        {
            timer += Time.deltaTime;

            // Check Events
            for(int i=0; i < events.Count; i++)
            {
                if (!triggeredIndices.Contains(i) && timer >= events[i].triggerTime)
                {
                    if(events[i].targetObject != null)
                    {
                        events[i].targetObject.SetActive(events[i].setActive);
                    }
                    triggeredIndices.Add(i);
                }
            }

            // Check VR Interaction
            if (enableInteraction && interactionTarget != null && PersistentCameraRig.Instance != null)
            {
                // Check Left Hand Trigger (Index or Hand) - OVRInput.Button.PrimaryIndexTrigger refers to the active controller's index trigger usually? 
                // Let's use specific: One (A/X), PrimaryIndexTrigger, etc.
                // User said "Index Trigger OR Middle Trigger".
                // Index = PrimaryIndexTrigger / SecondaryIndexTrigger
                // Middle = PrimaryHandTrigger / SecondaryHandTrigger
                
                bool leftClick = OVRInput.GetDown(OVRInput.Button.PrimaryIndexTrigger) || OVRInput.GetDown(OVRInput.Button.PrimaryHandTrigger);
                bool rightClick = OVRInput.GetDown(OVRInput.Button.SecondaryIndexTrigger) || OVRInput.GetDown(OVRInput.Button.SecondaryHandTrigger);
                
                // Also check legacy/generic "One" button just in case
                if(leftClick || rightClick)
                {
                    // Raycast Check
                    bool hit = false;
                    
                    if(leftClick && PersistentCameraRig.Instance.leftHandAnchor != null)
                    {
                        if(CheckRaycast(PersistentCameraRig.Instance.leftHandAnchor)) hit = true;
                    }
                    
                    if(!hit && rightClick && PersistentCameraRig.Instance.rightHandAnchor != null)
                    {
                        if(CheckRaycast(PersistentCameraRig.Instance.rightHandAnchor)) hit = true;
                    }
                    
                    if(hit)
                    {
                        // Interaction Success! Skip to next scene.
                        skipped = true;
                        break; // Exit loop
                    }
                }
            }

            yield return null;
        }

        // 2. Sequence Finished -> Start Transition (Fade Out + Effects)
        if (SceneFader.Instance != null && (!string.IsNullOrEmpty(nextSceneName) || loopScene))
        {
            // Start Fade Out
            SceneFader.Instance.FadeOut(fadeOutDuration);

            // Capture Camera
            Camera cam = Camera.main;
            Vector3 originalPos = (cam != null) ? cam.transform.localPosition : Vector3.zero;
            float startFov = (cam != null) ? cam.fieldOfView : 60f;

            float transTimer = 0f;
            while(transTimer < fadeOutDuration)
            {
                transTimer += Time.deltaTime;
                float t = transTimer / fadeOutDuration;

                if(cam != null)
                {
                    // A. Glitch Shake
                    if(enableGlitchShake)
                    {
                        // Increase strength as we fade out? Or constant? constant is fine.
                        Vector3 randomOffset = Random.insideUnitSphere * glitchIntensity * 0.1f; 
                        cam.transform.localPosition = originalPos + randomOffset;
                    }

                    // B. FOV Zoom
                    if(enableFovZoom)
                    {
                        // Linear interpolate FOV
                        cam.fieldOfView = Mathf.Lerp(startFov, targetFov, t);
                    }
                }

                yield return null;
            }

            // Restore Camera (Optional, scene will reload anyway but good practice)
            if(cam != null) cam.transform.localPosition = originalPos;

            // 3. Load Next Scene
            string targetScene = loopScene ? UnityEngine.SceneManagement.SceneManager.GetActiveScene().name : nextSceneName;
            UnityEngine.SceneManagement.SceneManager.LoadScene(targetScene);
            
            // Note: SceneFader will automatically handle the Fade In on the new scene 
            // IF SceneFader.Instance exists there (it does, DontDestroyOnLoad) 
            // AND we optionally trigger FadeIn in the new scene's FilmCutManager.
        }
        else
        {
            Debug.Log("[FilmCutManager] Cut finished. No next scene defined or Fader missing.");
        }
    }

    private bool CheckRaycast(Transform origin)
    {
        Ray ray = new Ray(origin.position, origin.forward);
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit, interactionDistance))
        {
            if (hit.collider.gameObject == interactionTarget)
            {
                return true;
            }
        }
        return false;
    }
}
