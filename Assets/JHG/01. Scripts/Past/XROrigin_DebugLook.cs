using Unity.XR.CoreUtils;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR.Interaction.Toolkit;
public class XROrigin_DebugLook : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    public XROrigin xrOrigin;

    [Header("Mouse Look")]
    public float mouseSensitivity = 0.1f;

    [Header("Snap Turn")]
    public float snapAngle = 10f;

    bool isLooking = false;

    void Awake()
    {
        if (!xrOrigin)
            xrOrigin = GetComponent<XROrigin>();
    }

    void Update()
    {
        HandleMouseLook();
        HandleSnapTurn();
    }

    void HandleMouseLook()
    {
        if (Mouse.current == null) return;

        // 오른쪽 마우스 누르고 있을 때만 Look
        isLooking = Mouse.current.rightButton.isPressed;

        if (!isLooking) return;

        float mouseX = Mouse.current.delta.x.ReadValue();
        float mouseY = Mouse.current.delta.y.ReadValue();

        // 좌우 회전 → XR Origin (Yaw)
        xrOrigin.transform.Rotate
            ( Vector3.up,
            mouseX * mouseSensitivity,
            Space.World
        );

        // 상하 회전 → Camera (Pitch)
        Transform cam = xrOrigin.Camera.transform;

        Vector3 angles = cam.localEulerAngles;

        // Euler 180 보정
        float pitch = angles.x > 180 ? angles.x - 360 : angles.x;
        pitch -= mouseY * mouseSensitivity;

        // 멀미 방지 제한
        pitch = Mathf.Clamp(pitch, -85f, 85f);

        cam.localEulerAngles = new Vector3
            (pitch,
            0f,
            0f);
    }

    void HandleSnapTurn()
    {
        if (Keyboard.current == null) return;

        if (Keyboard.current.qKey.wasPressedThisFrame)
        {
            xrOrigin.transform.Rotate(Vector3.up, -snapAngle);
        }
        else if (Keyboard.current.eKey.wasPressedThisFrame)
        {
            xrOrigin.transform.Rotate(Vector3.up, snapAngle);
        }
    }
}
