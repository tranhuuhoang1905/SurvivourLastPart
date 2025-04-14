using UnityEngine;
using TMPro;

public abstract class EnemyBase : MonoBehaviour
{
    [SerializeField] protected int penalty = -1;
    public TextMeshProUGUI scoreText;
    // private bool isMovingUp = false;
    

    protected virtual void Start()
    {
        
        scoreText.text = penalty.ToString() ;
        if (penalty > 0)
        {
            scoreText.color = Color.green;
        }
        else if (penalty < 0)
        {
            scoreText.color = Color.red;
        }
        else
        {
            scoreText.color = Color.white; // mặc định nếu = 0
        }
        // Có thể lấy service tại đây nếu dùng chung
    }

    protected virtual void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            HandleTriggerEnter(other.gameObject);
            // OnPlayerHit(other.gameObject);
            
            // isMovingUp = true;
            // StartCoroutine(DestroyAfterDelay(1f));
            // Destroy(gameObject);
        }
    }
    protected virtual void HandleTriggerEnter(GameObject player)
{
    OnPlayerHit(player);
    BeginFloatingAndDestroy();
}

    // private IEnumerator DestroyAfterDelay(float delay)
    // {
    //     yield return new WaitForSeconds(delay);
    //     Destroy(gameObject);
    // }

    protected abstract void OnPlayerHit(GameObject player);
    protected abstract void BeginFloatingAndDestroy();
}