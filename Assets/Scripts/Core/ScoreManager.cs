using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScoreManager : MonoBehaviour, IScoreService
{
    public static ScoreManager Instance { get; private set; }

    private int currentScore;

    // public event Action<int> OnScoreChanged;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
    }

    public void AddScore(int amount)
    {
        currentScore += amount;
        Debug.Log($"CurrentScore:{currentScore}");
        GameEvents.RaisePeachCollected(currentScore);
    }
}

