using TMPro;
using UnityEngine;

namespace GameNatra
{
    public class GateController : MonoBehaviour
    {
        #region Variables

        public int level;
        // [SerializeField] private LevelUlementView levelUlementView;
        [SerializeField] private GameObject mOriginObj;
        [SerializeField] private GameObject mDestructionObj;
        [SerializeField] private TextMeshProUGUI mTextBonus;
        public float bonusStats;
        private bool isFighted;
        private IScoreService scoreService;
        #endregion

        private void Start()
        {
            // if(levelUlementView!= null) levelUlementView.SetupView(level);
            // bonusStats = 1 + (level / 10) * 0.1f; ;
            if (mTextBonus) mTextBonus.text = $"X{level}";
            
            scoreService = ScoreManager.Instance;
        }

        private void OnTriggerEnter(Collider other)
        {
            if (other.CompareTag("Player"))
            {
                if (isFighted) return;
                // var isPassed = CharacterManager.Instance.CurrentCharacter.IncreasePlayerLevel(level, bonusStats);
                // if (isPassed)
                int IScore = scoreService.GetScore();
                Debug.Log($"check IScore:{IScore}");
                if (IScore >= level)
                {
                    isFighted = true;
                    if(mOriginObj) Destroy(mOriginObj);
                    if (mDestructionObj) mDestructionObj.SetActive(true);
                    if (mTextBonus) mTextBonus.gameObject.SetActive(false);
                }
                else
                {
                    GameEvents.TryKill();
                }
            }
        }
    }
}
