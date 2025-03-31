using UnityEngine;

public class PlayerJumpRigidController : MonoBehaviour
{
    public float jumpForce = 7f;

    private bool isGrounded = true;
    private Rigidbody rb;

    void Start()
    {
        rb = GetComponent<Rigidbody>();         // 👈 lấy Rigidbody
        rb.interpolation = RigidbodyInterpolation.Interpolate; // mượt khi FPS dao động
    }

    void Update()
    {
        CheckSpaceJump();
    }

    public void TryJump()
    {
        if (isGrounded)
        {
            PerformJump();
        }
    }

    private void CheckSpaceJump()
    {
        if (isGrounded && Input.GetKeyDown(KeyCode.Space))
        {
            PerformJump();
        }
    }

    private void PerformJump()
    {
        Debug.Log("check jump *******************");
        rb.velocity = new Vector3(rb.velocity.x, 0f, rb.velocity.z);
        rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
        isGrounded = false;
    }

    void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ground"))
        {
            isGrounded = true;
        }
    }
}
