using UnityEngine;
public class Enemy : EnemyBase
{
    private IScoreService scoreService;
    protected override void Start()
    {
        base.Start();
        scoreService = ScoreManager.Instance;
    }

    protected override void OnPlayerHit(GameObject player)
    {
        scoreService.AddScore(penalty);
    }
}