using UnityEngine;
using System.Collections;

public class BGMTrigger : MonoBehaviour
{
    public AudioSource bgmSource;
    public float fadeTime = 1.0f;

    Coroutine fadeRoutine;

    void Awake()
    {
        // 시작 볼륨을 기억해두고, 재생 전에 0으로 내려두면 페이드 인이 깔끔함
        if (bgmSource != null)
        {
            bgmSource.playOnAwake = false;
            bgmSource.loop = true;
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (!other.CompareTag("Player")) return;

        // 이미 페이드 중이면 중단
        if (fadeRoutine != null) StopCoroutine(fadeRoutine);

        // 재생 중이 아니면 시작
        if (!bgmSource.isPlaying) bgmSource.Play();

        fadeRoutine = StartCoroutine(FadeTo(bgmSource, 1f, fadeTime)); // 1f = 목표 볼륨(비율)
    }

    private void OnTriggerExit(Collider other)
    {
        if (!other.CompareTag("Player")) return;

        if (fadeRoutine != null) StopCoroutine(fadeRoutine);
        fadeRoutine = StartCoroutine(FadeOutAndStop(bgmSource, fadeTime));
    }

    IEnumerator FadeTo(AudioSource src, float target01, float time)
    {
        // "원래 볼륨"을 기준으로 비율 적용
        float baseVol = src.volume;     // 현재 볼륨을 베이스로 삼지 않게 하려면 아래 방식활용.
        // 더 안정적으로 하려면 baseVol을 별도 변수로 저장해두는 방식도 가능

        float start = src.volume;
        float target = Mathf.Clamp01(target01) * Mathf.Max(baseVol, 0.0001f);

        float t = 0f;
        while (t < time)
        {
            t += Time.unscaledDeltaTime;
            src.volume = Mathf.Lerp(start, target, t / time);
            yield return null;
        }
        src.volume = target;
    }

    IEnumerator FadeOutAndStop(AudioSource src, float time)
    {
        float start = src.volume;
        float t = 0f;
        while (t < time)
        {
            t += Time.unscaledDeltaTime;
            src.volume = Mathf.Lerp(start, 0f, t / time);
            yield return null;
        }
        src.volume = 0f;
        src.Stop();
    }
}
