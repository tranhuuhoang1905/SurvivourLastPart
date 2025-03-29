using UnityEngine;

public class PlayerAutoRunner : MonoBehaviour
{
    public float laneDistance = 2.0f; // khoảng cách giữa các làn
    public float forwardSpeed = 5.0f;
    public float laneChangeSpeed = 10.0f;

    private int currentLane = 1; // 0: trái, 1: giữa, 2: phải
    private Vector3 targetPosition;
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
    }

    void HandleInput()
    {
        if (Input.GetKeyDown(KeyCode.A) && currentLane > 0)
        {
            currentLane--;
        }
        else if (Input.GetKeyDown(KeyCode.D) && currentLane < 2)
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
        if (Input.GetKey(KeyCode.D) && currentLane < 2)
        {
            currentLane++;
        }
        else if (Input.GetKey(KeyCode.A) && currentLane > 0)
        {
            currentLane--;
        }
    }
}
