using UnityEngine;

public class PlayerSpawnPoint : MonoBehaviour
{
    private void OnEnable()
    {
        // Optional: Could register to a static list if we wanted to be fancy, 
        // but FindObjectOfType is fine for a single spawn point per scene.
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.cyan;
        Gizmos.DrawWireSphere(transform.position, 0.5f);
        Gizmos.DrawLine(transform.position, transform.position + transform.forward);
    }
}
