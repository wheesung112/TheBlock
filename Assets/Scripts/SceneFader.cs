using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using System.Collections;

public class SceneFader : MonoBehaviour
{
    public static SceneFader Instance;

    [Header("Settings")]
    public float fadeDuration = 1.0f;
    public Color fadeColor = Color.black;

    [Header("References (Assign Manually)")]
    public CanvasGroup fadeCanvasGroup;
    public Image fadeImage;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            // Optionally DontDestroyOnLoad if you want it to persist. 
            // If you place one in every scene manually, you might NOT want this, 
            // or you rely on the Singleton check to kill duplicates.
            // Let's keep it for safety but typically manual placement implies per-scene.
            // However, Fader needs to survive the scene load to Fade In during the next scene?
            // Actually, if you have a Fader in Scene A and Scene B:
            // Scene A fades out -> Load Scene B.
            // Scene A object is destroyed (unless DontDestroy).
            // Scene B object starts Black -> Fades In.
            // So we DON'T strictly need DontDestroyOnLoad if every scene has a Fader setup properly.
            // But preserving it is safer for state continuity. Use typical Singleton.
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
            return;
        }

        if (fadeCanvasGroup == null) fadeCanvasGroup = GetComponent<CanvasGroup>();
        if (fadeImage == null) fadeImage = GetComponent<Image>();

        if(fadeImage != null) fadeImage.color = fadeColor;
    }

    // Removed SetupUI() - User builds the UI manually.

    public void LoadScene(string sceneName)
    {
        StartCoroutine(ProcessSceneLoad(sceneName));
    }

    public void LoadScene(int sceneIndex)
    {
        StartCoroutine(ProcessSceneLoad(sceneIndex));
    }

    private IEnumerator ProcessSceneLoad(object sceneTarget)
    {
        yield return StartCoroutine(Fade(1f));

        if (sceneTarget is string) SceneManager.LoadScene((string)sceneTarget);
        else if (sceneTarget is int) SceneManager.LoadScene((int)sceneTarget);

        yield return null;

        yield return StartCoroutine(Fade(0f));
    }

    public void FadeIn(float duration)
    {
        fadeDuration = duration;
        StartCoroutine(Fade(0f));
    }

    public void FadeOut(float duration)
    {
        fadeDuration = duration;
        StartCoroutine(Fade(1f));
    }

    public void SetAlpha(float alpha)
    {
        if (fadeCanvasGroup != null)
        {
            fadeCanvasGroup.alpha = alpha;
            fadeCanvasGroup.blocksRaycasts = (alpha > 0.1f);
        }
    }

    private IEnumerator Fade(float targetAlpha)
    {
        if (fadeCanvasGroup == null) yield break;
        
        fadeCanvasGroup.blocksRaycasts = true; 
        
        float startAlpha = fadeCanvasGroup.alpha;
        float timer = 0f;

        while (timer < fadeDuration)
        {
            timer += Time.deltaTime;
            float t = timer / fadeDuration;
            t = t * t * (3f - 2f * t);
            
            fadeCanvasGroup.alpha = Mathf.Lerp(startAlpha, targetAlpha, t);
            yield return null;
        }

        fadeCanvasGroup.alpha = targetAlpha;
        fadeCanvasGroup.blocksRaycasts = (targetAlpha > 0.1f);
    }
}
