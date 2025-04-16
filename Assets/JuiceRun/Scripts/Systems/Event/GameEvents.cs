using System;
public static class GameEvents
{
    public static event Action<int> OnPeachCollected;
    public static event Action OnTryKill;
    public static event Action OnTryWin;
    public static event Action OnTryGotoBattlePlane;
    
    public static event Action<bool> OnFinalGame;
    public static void RaisePeachCollected(int currentScore)
    {
        OnPeachCollected?.Invoke(currentScore);
    }
    public static void TryKill()
    {
        OnTryKill?.Invoke();
    }

    public static void TryWin()
    {
        OnTryWin?.Invoke();
    }

    public static void TryGotoBattlePlane()
    {
        OnTryGotoBattlePlane?.Invoke();
    }

    public static void FinalGame(bool type)
    {
        OnFinalGame?.Invoke(type);
    }

}