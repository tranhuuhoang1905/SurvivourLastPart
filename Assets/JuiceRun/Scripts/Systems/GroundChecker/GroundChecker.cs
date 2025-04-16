using UnityEngine;

public class GroundChecker : IGroundChecker
{
    private readonly float rayDistance;
    private readonly LayerMask groundLayer;

    public GroundChecker(float rayDistance, LayerMask groundLayer)
    {
        this.rayDistance = rayDistance;
        this.groundLayer = groundLayer;
    }

    public bool IsGrounded(Transform origin)
    {
        Vector3 rayOrigin = origin.position + Vector3.up * 0.1f; 
        return Physics.Raycast(rayOrigin, Vector3.down, rayDistance, groundLayer);
    }
}