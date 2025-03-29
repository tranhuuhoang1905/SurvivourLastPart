using UnityEngine;

public class GroundByChecker : IGroundChecker
{
    public LayerMask groundLayer;
    public float rayDistance = 0.2f;

    public bool IsGroundedByY(Transform playerTransform)
    {
        return playerTransform.position.y <= 0.01f;
    }

    public bool IsGroundedByRayCast(Transform playerTransform)
    {
        return Physics.Raycast(playerTransform.position, Vector3.down, rayDistance, groundLayer);
    }

}