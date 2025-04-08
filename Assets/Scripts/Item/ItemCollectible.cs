using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ItemCollectible : MonoBehaviour
{
    private IScoreService scoreService;
    [SerializeField] protected int penalty = 1;

    private void Start()
    {
        scoreService = ScoreManager.Instance; // 👈 dùng singleton để lấy abstraction
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            scoreService.AddScore(penalty);
            Destroy(gameObject);
        }
    }
}
