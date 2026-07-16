using UnityEngine;
using System.Collections.Generic;

public class WireframeManager : MonoBehaviour
{
    public static WireframeManager Instance;

    private List<WireframeEffect> effects = new List<WireframeEffect>();

    [Header("Global Settings")]
    public float globalTransitionDuration = 1.0f;
    public bool startAllAsWireframe = false;

    [Header("Auto Sequence")]
    public bool autoActivateOnStart = false;
    public float autoActivateDelay = 3.0f;

    private void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    private void Start()
    {
        if (autoActivateOnStart)
        {
            StartCoroutine(WaitAndActivate());
        }
    }

    private System.Collections.IEnumerator WaitAndActivate()
    {
        yield return new WaitForSeconds(autoActivateDelay);
        ActivateAll();
    }

    public void Register(WireframeEffect effect)
    {
        if (!effects.Contains(effect)) effects.Add(effect);
        
        // Apply global start state if needed
        // Note: Individual Start() might override this if we are not careful.
    }

    public void Unregister(WireframeEffect effect)
    {
        if (effects.Contains(effect)) effects.Remove(effect);
    }

    [ContextMenu("Activate All Wireframes")]
    public void ActivateAll()
    {
        foreach (var effect in effects)
        {
            effect.transitionDuration = globalTransitionDuration;
            effect.ActivateWireframe();
        }
    }

    [ContextMenu("Revert All to Normal")]
    public void RevertAll()
    {
        foreach (var effect in effects)
        {
            effect.transitionDuration = globalTransitionDuration;
            effect.RevertToNormal();
        }
    }
    
    [ContextMenu("Toggle All")]
    public void ToggleAll()
    {
        // Check first one to decide state
        if(effects.Count == 0) return;
        
        bool anyWireframe = false;
        foreach(var e in effects) if(e.IsWireframe) { anyWireframe = true; break; }
        
        if(anyWireframe) RevertAll();
        else ActivateAll();
    }
}
