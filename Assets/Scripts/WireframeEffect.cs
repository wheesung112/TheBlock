using UnityEngine;
using System.Collections;

public class WireframeEffect : MonoBehaviour
{
    [Header("Assets")]
    public Mesh originalMesh; 
    public Mesh bakedMesh;
    
    [Header("Materials")]
    public Material[] originalMaterials; // Updated to Array
    public Material[] wireframeMaterials; // Updated to Array

    [Header("Settings")]
    public float transitionDuration = 1.0f;
    public bool startAsWireframe = false;

    private MeshFilter mf;
    private MeshRenderer mr;
    private bool isWireframe = false;
    public bool IsWireframe => isWireframe;

    void OnEnable()
    {
        if (WireframeManager.Instance != null) WireframeManager.Instance.Register(this);
    }

    void OnDisable()
    {
        if (WireframeManager.Instance != null) WireframeManager.Instance.Unregister(this);
    }

    void Start()
    {
        if (WireframeManager.Instance != null) WireframeManager.Instance.Register(this);

        mf = GetComponent<MeshFilter>();
        mr = GetComponent<MeshRenderer>();

        if (originalMesh == null && mf != null) originalMesh = mf.sharedMesh;
        
        // Auto-detect original materials if not assigned
        if ((originalMaterials == null || originalMaterials.Length == 0) && mr != null) 
        {
            originalMaterials = mr.sharedMaterials;
        }

        if (startAsWireframe) EnableWireframeImmediate();
    }

    [ContextMenu("Toggle Effect")]
    public void Toggle()
    {
        if (isWireframe) RevertToNormal();
        else ActivateWireframe();
    }

    private bool isTransitioning = false;

    public void ActivateWireframe()
    {
        if (isWireframe || isTransitioning) return;
        StartCoroutine(TransitionToWireframe());
    }

    public void RevertToNormal()
    {
        if (!isWireframe || isTransitioning) return;
        StartCoroutine(TransitionToNormal());
    }

    private void EnableWireframeImmediate()
    {
        if(bakedMesh != null) mf.sharedMesh = bakedMesh;
        if(wireframeMaterials != null && wireframeMaterials.Length > 0) 
            mr.sharedMaterials = ResizeMaterialArray(wireframeMaterials, mr.sharedMaterials.Length);
            
        isWireframe = true;
    }

    private void DisableWireframeImmediate()
    {
        if(originalMesh != null) mf.sharedMesh = originalMesh;
        if(originalMaterials != null && originalMaterials.Length > 0) 
            mr.sharedMaterials = originalMaterials;
            
        isWireframe = false;
    }

    // Helper to ensure material array matches submesh count
    private Material[] ResizeMaterialArray(Material[] materials, int targetLength)
    {
        if (materials.Length == targetLength) return materials;
        // If mismatch, repeat or truncate
        Material[] newMats = new Material[targetLength];
        for(int i=0; i<targetLength; i++)
        {
            newMats[i] = materials[i % materials.Length];
        }
        return newMats;
    }

    private IEnumerator TransitionToWireframe()
    {
        isTransitioning = true;
        
        // Flicker Effect
        int blinkCount = Random.Range(6, 11); // 6 to 10 times
        
        for(int i=0; i < blinkCount; i++)
        {
            // Toggle state
            // Even: Wireframe, Odd: Normal (or vice versa, let's just random or alternate)
            // Let's alternate.
            // i=0: Wireframe (Flash)
            // i=1: Normal
            // ...
            
            if(i % 2 == 0) EnableWireframeImmediate();
            else DisableWireframeImmediate();
            
            // Random short delay
            yield return new WaitForSeconds(Random.Range(0.05f, 0.2f));
        }

        // Final State: Ensure Wireframe
        EnableWireframeImmediate();
        
        isTransitioning = false;
    }

    private IEnumerator TransitionToNormal()
    {
        // 1. Animate Out
        Material[] instances = mr.materials;
        float timer = 0;
        
        // Get start amplitude from current state
        float startAmp = 0f;
        foreach(var m in instances) 
        {
            if(m.HasProperty("_GlitchAmplitude")) 
            {
                startAmp = m.GetFloat("_GlitchAmplitude");
                break;
            }
        }

        if(startAmp > 0)
        {
            while(timer < transitionDuration)
            {
                timer += Time.deltaTime;
                float t = timer / transitionDuration;
                float val = Mathf.Lerp(startAmp, 0f, t);
                
                foreach(var m in instances)
                {
                    if(m.HasProperty("_GlitchAmplitude")) m.SetFloat("_GlitchAmplitude", val);
                }
                yield return null;
            }
        }

        // 2. Swap back
        if(originalMaterials != null) mr.sharedMaterials = originalMaterials;
        if(originalMesh != null) mf.sharedMesh = originalMesh;

        isWireframe = false;
    }
}
