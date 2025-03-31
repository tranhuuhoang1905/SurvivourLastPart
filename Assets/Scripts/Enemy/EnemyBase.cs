using UnityEngine;

public abstract class EnemyBase : MonoBehaviour
{
    [SerializeField] protected int penalty = -1;

    protected virtual void Start()
    {
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