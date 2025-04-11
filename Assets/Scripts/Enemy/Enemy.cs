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
        var attackController = player.GetComponent<IAttack>();
        if (attackController != null)
        {
            attackController.TryAttack();
        }

        scoreService.AddScore(penalty);
    }
}