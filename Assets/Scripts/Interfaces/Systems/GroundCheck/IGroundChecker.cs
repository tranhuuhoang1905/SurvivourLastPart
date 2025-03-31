using UnityEngine;
public interface IGroundChecker
{
    bool IsGroundedByY(Transform playerTransform);
    bool IsGroundedByRayCast(Transform playerTransform);
}