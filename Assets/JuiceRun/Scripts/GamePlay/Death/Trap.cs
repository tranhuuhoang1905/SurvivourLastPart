using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Trap : MonoBehaviour
{
    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Player"))
        {
            GameEvents.TryKill();
            // Destroy(gameObject); // hoặc gameObject.SetActive(false);
        }
    }
}
