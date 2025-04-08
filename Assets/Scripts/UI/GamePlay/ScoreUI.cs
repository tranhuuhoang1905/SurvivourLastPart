using UnityEngine;
using TMPro;
public class ScoreUI : MonoBehaviour
{
    public TextMeshProUGUI scoreText;
    private int currentScore = 0;
    void Start()
    {

    }

    private void OnEnable()
    {
        GameEvents.OnPeachCollected += HandlePeachCollected;
    }

    private void OnDisable()
    {
        GameEvents.OnPeachCollected -= HandlePeachCollected;
    }

    private void HandlePeachCollected(int currentScore)
    {
        this.currentScore = currentScore;
        scoreText.text = "Score: " + this.currentScore;
    }
}
