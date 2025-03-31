using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudJumpItem : MonoBehaviour
{
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            var jumpController = other.GetComponent<PlayerJumpController>();
            if (jumpController != null)
            {
                jumpController.TryJump(); // 👈 Gọi trực tiếp nhảy!
            }

            Destroy(gameObject); // hoặc disable
        }
    }
}
