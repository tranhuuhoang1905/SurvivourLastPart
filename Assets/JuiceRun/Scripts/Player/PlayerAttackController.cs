using System.Collections;
using UnityEngine;

public class PlayerAttackController : MonoBehaviour, IAttack
{
    private Animator animator;
    private int comboStep = 0;

    private readonly string[] comboTriggers = { "IsAttack1", "IsAttack2" };

    void Start()
    {
        animator = GetComponent<Animator>();
    }

    void Update()
    {
        // Bạn có thể thêm combo timeout ở đây nếu muốn
    }

    public void TryAttack()
    {
        PerformAttack();
    }

    private void PerformAttack()
    {
        if (comboStep >= comboTriggers.Length)
        {
            ResetAttack();
        }
        animator.SetBool(comboTriggers[comboStep], true);
        comboStep ++ ;
    }

    public void ResetAttack()
    {
        ResetAllComboBools();
        comboStep = 0;
    }

    private void ResetAllComboBools()
    {
        foreach (var trigger in comboTriggers)
        {
            animator.SetBool(trigger, false);
        }
    }

    public void TryActionComboSkill()
    {
        animator.SetBool("IsComboSkill", true);
    }
}
