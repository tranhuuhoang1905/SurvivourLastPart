using System;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class PlayerJumpController : MonoBehaviour, IJumpable
{
    [Header("Jump Settings")]
    public float jumpForce = 7f;
    public float groundCheckDistance = 0.2f;
    public LayerMask groundLayer;

    private Rigidbody rb;
    private bool isGrounded;
    private Animator animator;
    private bool isDead = false;
    private IGroundChecker groundChecker;

    void Start()
    {
        groundChecker = new GroundChecker(groundCheckDistance, groundLayer);
    }
    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
        rb.constraints = RigidbodyConstraints.FreezeRotation;
        animator = GetComponent<Animator>();
    }

    private void OnEnable()
    {
        GameEvents.OnFinalGame += FinalGame;
    }

    private void OnDisable()
    {
        GameEvents.OnFinalGame -= FinalGame;
    }
    private void Update()
    {
        if (isDead) return;

        bool checkGrounded = groundChecker.IsGrounded(transform);
        if (checkGrounded != isGrounded)
        {
            isGrounded = checkGrounded;
            animator.SetBool("IsJump", !isGrounded);
        }

        
        
        // if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
        // {
        //     PerformJump();
        // }
    }
    
    private void PerformJump()
    {
        rb.velocity = new Vector3(rb.velocity.x, jumpForce, rb.velocity.z);
        isGrounded = false;
        // animator.SetBool("IsJump", !isGrounded);
    }

    public void TryJump()
    {
        if (isDead || !isGrounded) return;
        PerformJump();
    }

    public void FinalGame(bool _type)
    {
        animator.SetBool("IsJump", false);
        isDead = true;
        rb.velocity = new Vector3(rb.velocity.x, 0f, rb.velocity.z);
    }

    public void ResumeJump()
    {
        isDead = false;
    }
}