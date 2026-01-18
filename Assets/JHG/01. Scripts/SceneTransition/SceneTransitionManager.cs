using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections;

public class SceneTransitionManager : MonoBehaviour
{
    public static SceneTransitionManager Instance { get; private set; }

    [Header("Fade UI")]
    public CanvasGroup fadeCanvas;

    [Header("Timing")]
    public float fadeDuration = 1.2f;
    public float postLoadBlackHold = 0.05f; // 로드 직후 아주 짧게 검정 유지(깜빡임 방지용)

    [Header("Behavior")]
    public bool startWithFadeIn = false;     // 앱 첫 시작 씬에서 검정->투명 페이드인을 할지
    public bool blockInputWhileFading = true;

    private bool isTransitioning = false;

    private void Awake()
    {
        // 싱글턴 + 유지
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);

        if (fadeCanvas == null)
        {
            Debug.LogError("[SceneTransitionManager] fadeCanvas(CanvasGroup)가 연결되지 않았습니다.");
            return;
        }

        // 시작 상태 설정
        if (startWithFadeIn)
        {
            fadeCanvas.alpha = 1f; // 검정 시작
        }
        else
        {
            fadeCanvas.alpha = 0f; // 투명 시작(시작 페이드 없음)
        }

        SetInputBlock(fadeCanvas.alpha > 0.99f);
    }

    private void Start()
    {
        // 첫 시작 씬에서만 옵션에 따라 페이드인
        if (startWithFadeIn && fadeCanvas != null && fadeCanvas.alpha > 0.99f)
        {
            StartCoroutine(Fade(1f, 0f));
        }
    }

    public void TransitionTo(string sceneName)
    {
        Debug.Log("TransitionTo called: " + sceneName);
        if (isTransitioning) return;
        StartCoroutine(TransitionRoutine(sceneName));
    }

    private IEnumerator TransitionRoutine(string sceneName)
    {
        if (fadeCanvas == null) yield break;

        isTransitioning = true;

        // 1) Fade Out
        yield return Fade(0f, 1f);

        // 2) Load Scene Async
        AsyncOperation op = SceneManager.LoadSceneAsync(sceneName);
        if (op == null)
        {
            Debug.LogError("[SceneTransitionManager] LoadSceneAsync 실패: " + sceneName);
            isTransitioning = false;
            yield break;
        }

        // 로딩 중엔 계속 검정 유지
        while (!op.isDone)
        {
            yield return null;
        }

        // 3) 로드 직후 잠깐 검정 유지(선택)
        if (postLoadBlackHold > 0f)
            yield return new WaitForSeconds(postLoadBlackHold);

        // 4) Fade In
        yield return Fade(1f, 0f);

        isTransitioning = false;
    }

    private IEnumerator Fade(float from, float to)
    {
        if (fadeCanvas == null) yield break;

        SetInputBlock(true);

        float t = 0f;
        while (t < fadeDuration)
        {
            t += Time.deltaTime;
            fadeCanvas.alpha = Mathf.Lerp(from, to, t / fadeDuration);
            yield return null;
        }
        fadeCanvas.alpha = to;

        // 완전히 투명이 되면 입력막기 해제
        SetInputBlock(!Mathf.Approximately(to, 0f));
    }

    private void SetInputBlock(bool block)
    {
        if (!blockInputWhileFading || fadeCanvas == null)
        {
            if (fadeCanvas != null)
            {
                fadeCanvas.blocksRaycasts = false;
                fadeCanvas.interactable = false;
            }
            return;
        }

        fadeCanvas.blocksRaycasts = block;
        fadeCanvas.interactable = block;
    }
}
