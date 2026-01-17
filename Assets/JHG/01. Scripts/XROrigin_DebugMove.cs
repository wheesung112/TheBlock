using Unity.XR.CoreUtils;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR.Interaction.Toolkit;

public class XROrigin_DebugMove : MonoBehaviour
{
  
    public XROrigin xrOrigin;
    public float moveSpeed = 2f;

    Vector2 moveInput;

    void Awake()
    {
        if (!xrOrigin)
            xrOrigin = GetComponent<XROrigin>();
    }

    // PlayerInput의 Move 이벤트에서 호출됨
    public void OnMove(InputAction.CallbackContext context)
    {
        moveInput = context.ReadValue<Vector2>();
    }


    // Update is called once per frame
    void Update()
    {
        if (moveInput == Vector2.zero) return;

        Transform cam = xrOrigin.Camera.transform;

        Vector3 direction =
            cam.forward * moveInput.y +
            cam.right * moveInput.x;

        direction.y = 0f;

        xrOrigin.transform.position +=
            direction * moveSpeed * Time.deltaTime;
    }
}
