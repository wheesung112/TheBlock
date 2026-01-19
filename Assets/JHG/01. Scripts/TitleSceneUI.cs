using UnityEngine;
using UnityEngine.SceneManagement;

public class TitleSceneUI : MonoBehaviour
{
    [SerializeField] private string sceneAName = "SceneA"; // 씬 파일 이름과 동일하게

    public void OnClickStart()
    {
        SceneManager.LoadScene(sceneAName);
    }

    public void OnClickExit()
    {
        Application.Quit();
    }
}