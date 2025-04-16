using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ItemCollectible : MonoBehaviour
{
    private IScoreService scoreService;
    [SerializeField] protected int penalty = 1;
    private bool isMovingUp = false;
    private float MovingUpSpeed = 20f;

    private void Start()
    {
        scoreService = ScoreManager.Instance; // 👈 dùng singleton để lấy abstraction
    }
    
    private void Update()
    {
        if (isMovingUp)
        {
            Vector3 moveDirection = Vector3.up + (transform.forward);
            transform.Translate(moveDirection.normalized * MovingUpSpeed * Time.deltaTime);
        }
    }
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            scoreService.AddScore(penalty);
            isMovingUp = true;
            StartCoroutine(DestroyAfterDelay(1f));
        }
    }
    private IEnumerator DestroyAfterDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        Destroy(gameObject);
    }
}
