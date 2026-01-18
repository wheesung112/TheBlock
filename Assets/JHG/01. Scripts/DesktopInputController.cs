using Unity.XR.CoreUtils;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR.Interaction.Toolkit;

public class DesktopInputController : MonoBehaviour
{
   /* XROrigin xrOrigin;
    Transform cam;
    // float pitch;

    public InputActionReference move;
    public InputActionReference look;
    public InputActionReference snapTurn;
    public InputActionReference pause;
    public InputActionReference restart;

  
    void OnEnable()
    {
        xrOrigin = GetComponent<XROrigin>();
        RefreshCamera();

        move.action.Enable();
        look.action.Enable();
        snapTurn.action.Enable();
        pause.action.Enable();
        restart.action.Enable();
    }

    void OnDisable()
    {
        move.action.Disable();
        look.action.Disable();
        snapTurn.action.Disable();
        pause.action.Disable();
        restart.action.Disable();
    }

    void RefreshCamera()
    {
        cam = xrOrigin.Camera.transform;
    }

    void OnApplicationFocus(bool hasFocus)
    {
        if (hasFocus)
            RefreshCamera();
    }

    void Update()
    {
        Vector2 m = move.action.ReadValue<Vector2>();
        Vector2 l = look.action.ReadValue<Vector2>();

        if (m != Vector2.zero)
            Debug.Log("Move input: " + m);

        if (l != Vector2.zero)
            Debug.Log("Look input: " + l);

   
    } */


    [Header("XR Origin")]
    public XROrigin xrOrigin;

    [Header("Movement")]
    public InputActionReference moveAction;
    public float moveSpeed = 2.0f;

    [Header("Look")]
    public InputActionReference lookAction;
    public float lookSensitivity = 0.1f;

    [Header("Snap Turn")]
    public InputActionReference snapTurnAction;
    public float snapAngle = 10f;

    [Header("Pause / Restart")]
    public InputActionReference pauseAction;
    public InputActionReference restartAction;

    float snapCooldown = 0.25f;
    float lastSnapTime;

    float pitch = 0f;

    void OnEnable()
    {
        moveAction.action.Enable();
        lookAction.action.Enable();
        snapTurnAction.action.Enable();
        pauseAction.action.Enable();
        restartAction.action.Enable();
    }

    void OnDisable()
    {
        moveAction.action.Disable();
        lookAction.action.Disable();
        snapTurnAction.action.Disable();
        pauseAction.action.Disable();
        restartAction.action.Disable();
    }

    void Update()
    {
        HandleMove();
        HandleLook();
        HandleSnapTurn();
        HandlePauseRestart();
    }

    void HandleMove()
    {
        Vector2 input = moveAction.action.ReadValue<Vector2>();
        if (input == Vector2.zero) return;

        Transform camera = xrOrigin.Camera.transform;

        Vector3 forward = Vector3.ProjectOnPlane(camera.forward, Vector3.up).normalized;
        Vector3 right = Vector3.ProjectOnPlane(camera.right, Vector3.up).normalized;

        Vector3 move = forward * input.y + right * input.x;
        xrOrigin.transform.position += move * moveSpeed * Time.deltaTime;
    }

    void HandleLook()
    {
        if (!Mouse.current.rightButton.isPressed) return;

        Vector2 delta = lookAction.action.ReadValue<Vector2>();
        if (delta == Vector2.zero) return;

        // yaw (좌우 회전)
        xrOrigin.transform.Rotate(Vector3.up, delta.x * lookSensitivity);

        // pitch (상하 회전)
        pitch -= delta.y * lookSensitivity;
        pitch = Mathf.Clamp(pitch, -80f, 80f);

        xrOrigin.Camera.transform.localRotation = Quaternion.Euler(pitch, 0f, 0f);
    }

    void HandleSnapTurn()
    {
        float value = snapTurnAction.action.ReadValue<float>();
        if (Mathf.Abs(value) < 0.5f) return;
        if (Time.time - lastSnapTime < snapCooldown) return;

        xrOrigin.transform.Rotate(Vector3.up, Mathf.Sign(value) * snapAngle);
        lastSnapTime = Time.time;
    }

    void HandlePauseRestart()
    {
        if (pauseAction.action.WasPressedThisFrame())
        {
            Debug.Log("Pause triggered");
            Time.timeScale = Time.timeScale == 0 ? 1 : 0;
        }

        if (restartAction.action.WasPressedThisFrame())
        {
            Debug.Log("Restart triggered");
            Time.timeScale = 1;
            UnityEngine.SceneManagement.SceneManager.LoadScene(0);
        }
    }
}
