using UnityEngine;

public class PlayerJumpController : MonoBehaviour
{
    public float jumpForce = 7f;
    public float gravity = 10f;

    private float verticalVelocity = 0f;
    private bool isGrounded = true;
    private IGroundChecker groundChecker;
    
    void Start()
    {
        groundChecker = new GroundByChecker(); // 👈 Khởi tạo class cụ thể
    }
    void Update()
    {
        isGrounded = groundChecker.IsGroundedByY(transform);
        HandleJump();
    }

    void HandleJump()
    {
        if (isGrounded && Input.GetKeyDown(KeyCode.Space))
        {
            verticalVelocity = jumpForce;
            isGrounded = false;
        }

        if (!isGrounded)
        {
            verticalVelocity -= gravity * Time.deltaTime;
            transform.Translate(Vector3.up * verticalVelocity * Time.deltaTime);

            if (transform.position.y <= 0f)
            {
                Vector3 pos = transform.position;
                pos.y = 0f;
                transform.position = pos;

                verticalVelocity = 0f;
                isGrounded = true;
            }
        }
    }

}
