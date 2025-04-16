using UnityEngine;

public class PlayerLifeController : MonoBehaviour,IKillable
{
    private PlayerAutoRunner autoRunner;
    private PlayerJumpController playerJump;
    void Awake()
    {
        // autoRunner = GetComponent<PlayerAutoRunner>();
        // playerJump = GetComponent<PlayerJumpController>();
    }

    private void OnEnable()
    {
        GameEvents.OnTryKill += TryKill;
        GameEvents.OnTryWin += TryWin;
    }

    private void OnDisable()
    {
        GameEvents.OnTryKill -= TryKill;
        GameEvents.OnTryWin -= TryWin;
    }
    public void TryKill()
    {
        GameEvents.FinalGame(false);

    }
    public void TryWin()
    {
        GameEvents.FinalGame(true);

    }
}
