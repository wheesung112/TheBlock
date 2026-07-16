using UnityEngine;

public class MaterialOffsetAnimator : MonoBehaviour
{
    [SerializeField] private Vector2 scrollSpeed = new Vector2(0.1f, 0f);
    [SerializeField] private string texturePropertyName = "_BaseMap"; // Default for URP/HDRP. Change to "_MainTex" for Built-in.

    private Renderer _renderer;
    private Material _materialInstance;

    void Start()
    {
        _renderer = GetComponent<Renderer>();
        if (_renderer != null)
        {
            // Creates an instance of the material so they can animate independently
            _materialInstance = _renderer.material;
        }
    }

    void Update()
    {
        if (_materialInstance != null)
        {
            if (_materialInstance.HasProperty(texturePropertyName))
            {
                Vector2 currentOffset = _materialInstance.GetTextureOffset(texturePropertyName);
                currentOffset += scrollSpeed * Time.deltaTime;
                _materialInstance.SetTextureOffset(texturePropertyName, currentOffset);
            }
            else if (_materialInstance.HasProperty("_MainTex"))
            {
                // Fallback to _MainTex if the specified property doesn't exist
                Vector2 currentOffset = _materialInstance.GetTextureOffset("_MainTex");
                currentOffset += scrollSpeed * Time.deltaTime;
                _materialInstance.SetTextureOffset("_MainTex", currentOffset);
            }
        }
    }

    void OnDestroy()
    {
        // Clean up instantiated material to prevent memory leaks
        if (_materialInstance != null)
        {
            Destroy(_materialInstance);
        }
    }
}
