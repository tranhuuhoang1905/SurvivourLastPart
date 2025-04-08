using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class PlayerAutoRunner : MonoBehaviour
{
    public float forwardSpeed = 5.0f;
    public float horizontalSpeed = 5.0f;
    public float xLimit = 4.0f;
    private bool isDead = false; // Thêm biến trạng thái
    private Animator animator;

    private Rigidbody rb;
    private Vector3 forwardVelocity;

    private void OnEnable()
    {
        GameEvents.OnFinalGame += FinalGame;
    }

    private void OnDisable()
    {
        GameEvents.OnFinalGame -= FinalGame;
    }

    void Awake()
    {
        rb = GetComponent<Rigidbody>();
        rb.constraints = RigidbodyConstraints.FreezeRotation; // Không cho xoay
        animator = GetComponent<Animator>();
    }

    void FixedUpdate()
    {
        MoveForward();
        HandleHorizontalInput();
    }

    void MoveForward()
    {
        forwardVelocity = Vector3.forward * forwardSpeed;
    }

    void HandleHorizontalInput()
    {
        if (isDead) return ;
        float horizontalInput = 0f;

        if (Input.GetKey(KeyCode.A))
        {
            horizontalInput = -1f;
        }
        else if (Input.GetKey(KeyCode.D))
        {
            horizontalInput = 1f;
        }

        Vector3 horizontalMove = Vector3.right * horizontalInput * horizontalSpeed;

        // Tính toán vị trí mới
        Vector3 move = (forwardVelocity + horizontalMove) * Time.fixedDeltaTime;
        Vector3 newPosition = rb.position + move;

        // Giới hạn trục X
        newPosition.x = Mathf.Clamp(newPosition.x, -xLimit, xLimit);

        rb.MovePosition(newPosition);
    }

    public void FinalGame( bool type)
    {
        
        isDead = true; // Đánh dấu đã chết
        forwardSpeed = 0f;
        rb.velocity = Vector3.zero; // Dừng lại lập tức nếu đang có momentum
        if(type) 
        {
            animator.SetBool("IsWinner", true);
        }
        else
        {
            
            animator.SetBool("IsLose", true);
        }
    }
}
