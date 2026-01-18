using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections;

public class SceneLoader : MonoBehaviour
{
    [SerializeField] FadeController fade;
    [SerializeField] string nextScene;

    public void Load()
    {
        StartCoroutine(LoadRoutine());
    }

    IEnumerator LoadRoutine()
    {
       // fade.FadeOut();
        yield return new WaitForSeconds(1f);
        SceneManager.LoadScene(nextScene);
    }
}