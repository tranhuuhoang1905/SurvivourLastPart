using UnityEngine;
using TMPro;

public abstract class EnemyBase : MonoBehaviour
{
    [SerializeField] protected int penalty = -1;
    public TextMeshProUGUI scoreText;

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
            OnPlayerHit(other.gameObject);
            Destroy(gameObject);
        }
    }

    protected abstract void OnPlayerHit(GameObject player);
}