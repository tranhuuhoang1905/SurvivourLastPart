using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Boss : EnemyBase
{
    private IScoreService scoreService;
    private Animator animator;
    protected override void Start()
    {
        base.Start();
        scoreService = ScoreManager.Instance;
    }
    
    private void Awake()
    {
        // animator = GetComponent<Animator>();
        animator = transform.Find("Enemy").GetComponent<Animator>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    protected override void OnPlayerHit(GameObject player)  
    {
        
        animator.SetBool("IsAttack", true);
        var attackController = player.GetComponent<IAttack>();
        if (attackController != null)
        {
            attackController.TryActionComboSkill();
        }

        var autoRunController = player.GetComponent<PlayerAutoRunner>();
        if (autoRunController != null)
        {
            autoRunController.Combat();
        }
        // scoreService.AddScore(penalty);
    }
    protected override void BeginFloatingAndDestroy()
    {
        StartCoroutine(DestroyAfterDelay(4f));
    }
    private IEnumerator DestroyAfterDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        var score = scoreService.GetScore();
        if (score>=penalty)
            {
                GameEvents.TryWin();
                animator.SetTrigger("IsDeath");
            }
            else{
                GameEvents.TryKill();
            }
    }
}
