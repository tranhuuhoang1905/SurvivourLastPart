using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WinPlane : MonoBehaviour
{
    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Player"))
        {
            GameEvents.TryWin();
            // Destroy(gameObject); // hoặc gameObject.SetActive(false);
        }
    }
}
