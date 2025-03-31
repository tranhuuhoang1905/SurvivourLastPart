using System;
public static class GameEvents
{
    public static event Action<int> OnPeachCollected;
    public static void RaisePeachCollected(int currentScore)
    {
        OnPeachCollected?.Invoke(currentScore);
    }
}