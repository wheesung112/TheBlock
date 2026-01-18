using UnityEngine;

public class SceneChangeOnZoneEnter : MonoBehaviour
{
    public string nextSceneName;
    private bool triggered = false;

    private void OnTriggerEnter(Collider other)
    {
        Debug.Log("Zone Trigger Enter: " + other.name); // 호출 확인용

        if (triggered) return;
        if (!other.CompareTag("Player")) return;

        triggered = true;

        if (SceneTransitionManager.Instance == null)
        {
            Debug.LogError("SceneTransitionManager.Instance is NULL (Title 씬에 매니저가 있는지 확인)");
            return;
        }

        SceneTransitionManager.Instance.TransitionTo(nextSceneName);
    }
}
