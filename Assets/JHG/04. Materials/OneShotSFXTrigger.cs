using UnityEngine;

public class OneShotSFXTrigger : MonoBehaviour
{
    public AudioSource sfxSource;
    private bool hasPlayed = false;


    private void OnTriggerEnter(Collider other)
    {
        Debug.Log("SFX Trigger Enter: " + other.name);
        if (other.CompareTag("Player") && !hasPlayed)
        {
            sfxSource.PlayOneShot(sfxSource.clip);
            hasPlayed = true;
        }
    }
}
