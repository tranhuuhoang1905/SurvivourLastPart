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
        checkSpaceJump();
        HandleJump();
    }
    public void TryJump()
    {
        if (isGrounded)
        {
            PeformJump();
        }
        HandleJump();
    }

    void checkSpaceJump()
    {
        if (isGrounded && Input.GetKeyDown(KeyCode.Space))
        {
            PeformJump();
        }
    }
    private void PeformJump()
    {
        verticalVelocity = jumpForce;
        isGrounded = false;
    }

    void HandleJump()
    {
        

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
