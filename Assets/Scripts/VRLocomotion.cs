using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class VRLocomotion : MonoBehaviour
{
    [Header("Movement Settings")]
    public float moveSpeed = 2.0f;
    public float gravity = -9.81f;
    private CharacterController characterController;

    [Header("Snap Turn Settings")]
    public float snapAngle = 45.0f;
    public float snapDeadZone = 0.8f; // Joystick threshold
    private bool isReadyToSnap = true;

    [Header("References")]
    public Transform cameraRigTransform;
    public Transform centerEyeAnchor;

    private void Start()
    {
        characterController = GetComponent<CharacterController>();
        
        if (cameraRigTransform == null) cameraRigTransform = transform;
        
        if (centerEyeAnchor == null)
        {
            var rig = GetComponent<OVRCameraRig>();
            if (rig != null) centerEyeAnchor = rig.centerEyeAnchor;
            else centerEyeAnchor = transform.Find("TrackingSpace/CenterEyeAnchor");
        }
    }

    private void Update()
    {
        HandleMovement();
        HandleSnapTurn();
    }

    private void HandleMovement()
    {
        // 1. Get Input (Left Stick)
        Vector2 input = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick);
        
        // 2. Calculate Direction relative to Camera Facing
        if (centerEyeAnchor == null) return;

        Vector3 forward = centerEyeAnchor.forward;
        Vector3 right = centerEyeAnchor.right;

        // Flatten direction (we don't want to fly up into the sky)
        forward.y = 0;
        right.y = 0;
        forward.Normalize();
        right.Normalize();

        Vector3 moveDir = (forward * input.y + right * input.x).normalized;

        // 3. Apply Movement
        if (characterController != null)
        {
            // Apply Gravity
            Vector3 velocity = moveDir * moveSpeed;
            // Simple gravity hack: if grounded, minimal y, else gravity
            if (!characterController.isGrounded)
            {
                velocity.y = gravity; // Just constant downward force for now, or accumulate if needed
            }
            
            characterController.Move(velocity * Time.deltaTime);
        }
        else
        {
            // Fallback (No Collider)
            transform.position += moveDir * moveSpeed * Time.deltaTime;
        }
    }

    private void HandleSnapTurn()
    {
        // 1. Get Input (Right Stick)
        Vector2 input = OVRInput.Get(OVRInput.Axis2D.SecondaryThumbstick);

        // 2. Check Snap
        if (Mathf.Abs(input.x) > snapDeadZone)
        {
            if (isReadyToSnap)
            {
                float turnAmount = (input.x > 0) ? snapAngle : -snapAngle;
                transform.Rotate(0, turnAmount, 0);
                isReadyToSnap = false; // Block until reset
            }
        }
        else
        {
            isReadyToSnap = true; // Reset when stick released
        }
    }
}
