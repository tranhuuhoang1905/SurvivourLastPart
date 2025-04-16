using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    [SerializeField] private GameObject countdownUI;
    [SerializeField] private TMPro.TextMeshProUGUI countdownText;

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
        ShowCountdownUI(true);

        int countdown = 3;
        while (countdown > 0)
        {
            UpdateCountdownText(countdown.ToString());
            yield return new WaitForSecondsRealtime(1f);
            countdown--;
        }

        UpdateCountdownText("Go!");
        yield return new WaitForSecondsRealtime(1f);

        ShowCountdownUI(false);
        Time.timeScale = 1f;
        // StartGame();
    }

    private void ShowCountdownUI(bool show)
    {
        if (countdownUI != null)
            countdownUI.SetActive(show);
    }

    private void UpdateCountdownText(string text)
    {
        if (countdownText != null)
            countdownText.text = text;
    }
}

