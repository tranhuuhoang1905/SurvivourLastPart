using UnityEngine;

public class LaneMovement : MonoBehaviour
{
    public float laneDistance = 2.0f; // khoảng cách giữa các làn
    public float forwardSpeed = 5.0f;
    public float laneChangeSpeed = 10.0f;

    private int currentLane = 1; // 0: trái, 1: giữa, 2: phải
    private Vector3 targetPosition;

    public float jumpForce = 7f;
    public float gravity = 20f;

    private float verticalVelocity = 0f;
    private bool isGrounded = true;
    public float laneEpsilon = 0.5f;

    void Start()
    {
        targetPosition = transform.position;
    }

    void Update()
    {
        HandleInput();
        MoveForward();
        MoveToLane();
        HandleJump();
    }

    void HandleInput()
    {
        if (Input.GetKeyDown(KeyCode.LeftArrow) && currentLane > 0)
        {
            currentLane--;
        }
        else if (Input.GetKeyDown(KeyCode.RightArrow) && currentLane < 2)
        {
            currentLane++;
        }
    }

    void MoveForward()
    {
        transform.Translate(Vector3.forward * forwardSpeed * Time.deltaTime);
    }

    void MoveToLane()
    {
        float targetX = (currentLane - 1) * laneDistance;
        float currentY = transform.position.y;
        float currentZ = transform.position.z;

        Vector3 currentPos = transform.position;
        Vector3 targetPos = new Vector3(targetX, currentY, currentZ);

        // Chỉ thay đổi trục X (giữ nguyên Y và Z)
        Vector3 newPosition = Vector3.MoveTowards(currentPos, targetPos, laneChangeSpeed * Time.deltaTime);
        transform.position = new Vector3(newPosition.x, currentPos.y, newPosition.z);

        // Khi đã gần tới đúng vị trí thì check giữ phím
        
        if (Mathf.Abs(transform.position.x) <= laneEpsilon)
        {
            CheckAndContinueMove();
        }
    }

    void CheckAndContinueMove()
    {
        if (Input.GetKey(KeyCode.RightArrow) && currentLane < 2)
        {
            currentLane++;
        }
        else if (Input.GetKey(KeyCode.LeftArrow) && currentLane > 0)
        {
            currentLane--;
        }
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

            // Hạ xuống và chạm đất
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
