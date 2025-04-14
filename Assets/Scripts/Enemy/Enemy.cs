using UnityEngine;
using System.Collections;
public class Enemy : EnemyBase
{
    private IScoreService scoreService;
    private bool isMovingUp = false;
    private float MovingUpSpeed = 10f;
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

    private void Update()
    {
        if (isMovingUp)
        {
            Vector3 moveDirection = Vector3.up + (transform.forward);
            transform.Translate(moveDirection.normalized * MovingUpSpeed * Time.deltaTime);
        }
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
    protected override void BeginFloatingAndDestroy()
    {
        
        animator.SetBool("Death", true);
        isMovingUp = true;
        StartCoroutine(DestroyAfterDelay(1f));
    }
    private IEnumerator DestroyAfterDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        Destroy(gameObject);
    }
}