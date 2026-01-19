using Unity.XR.CoreUtils;
using UnityEngine;
using UnityEngine.SceneManagement;

public class XROriginRepositioner : MonoBehaviour
{
    [Tooltip("씬에 있는 RepositionPoint 이름")]
    public string repositionPointName = "RepositionPoint";

    void OnEnable()
    {
        SceneManager.sceneLoaded += OnSceneLoaded;
    }

    void OnDisable()
    {
        SceneManager.sceneLoaded -= OnSceneLoaded;
    }

    void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        var spawn = GameObject.Find(repositionPointName);
        if (spawn == null) return;

        // XROrigin 찾기
        // FindObjectOfType는 deprecated → FindFirstObjectByType 사용
        var xrOrigin = Object.FindFirstObjectByType<XROrigin>();
        if (xrOrigin == null) return;

        // XR Origin 이동
        xrOrigin.transform.SetPositionAndRotation(
            spawn.transform.position,
            spawn.transform.rotation
        );
    }
}
