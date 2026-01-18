using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

public class ControlKeys : MonoBehaviour
{
    bool isPaused = false;

    void Update()
    {
        if (Keyboard.current == null) return;

        // P : Pause / Resume
        if (Keyboard.current.pKey.wasPressedThisFrame)
        {
            isPaused = !isPaused;
            Time.timeScale = isPaused ? 0f : 1f;
        }

        // R : Restart
        if (Keyboard.current.rKey.wasPressedThisFrame)
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene(
                SceneManager.GetActiveScene().buildIndex
            );
            // LoadScene("Title"); 나중에 타이틀씬 제작 후 변경
        }
    }
}
