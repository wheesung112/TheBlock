using UnityEngine;
using System.Collections;

public class FadeController : MonoBehaviour
{
    public CanvasGroup canvasGroup;
    public float duration = 2f;

    void Start()
    {
        canvasGroup.alpha = 0f;
        StartCoroutine(FadeIn());
    }

    IEnumerator FadeIn()
    {
        float t = 0f;
        while (t < duration)
        {
            t += Time.deltaTime;
            canvasGroup.alpha = t / duration;
            Debug.Log(canvasGroup.alpha);
            yield return null;
        }

        canvasGroup.alpha = 1f;
    }
}