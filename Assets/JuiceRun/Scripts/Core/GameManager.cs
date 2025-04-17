using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }
    
    private int level = 1;


    // public event Action<int> OnScoreChanged;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        // DontDestroyOnLoad(gameObject);
    }

    private void Start()
    {
        Time.timeScale = 0f; // Pause toàn bộ game
        StartCoroutine(CountdownToStart());
    }

    private IEnumerator CountdownToStart()
    {
        UIController.Instance.ShowCountdownUI(true);

        int countdown = 3;
        while (countdown > 0)
        {
            UIController.Instance.UpdateCountdownText(countdown.ToString());

            yield return new WaitForSecondsRealtime(1f);
            countdown--;
        }

        UIController.Instance.UpdateCountdownText("Go!");

        yield return new WaitForSecondsRealtime(1f);

        UIController.Instance.ShowCountdownUI(false);
        Time.timeScale = 1f;
        // StartGame();
    }

    
}

