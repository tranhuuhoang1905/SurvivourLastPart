using UnityEngine;
using TMPro;
using UnityEngine.SceneManagement;
using DG.Tweening;
using System.Collections;

public class UIController : MonoBehaviour
{
    // Start is called before the first frame update
    public static UIController Instance { get; private set; }
    private TextMeshProUGUI textFinal;
    [SerializeField] private GameObject panel;
    [SerializeField] private GameObject WinImage;
    [SerializeField] private GameObject LoseImage;
    [SerializeField] private GameObject countdownUI;
    [SerializeField] private TMPro.TextMeshProUGUI countdownText;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        // DontDestroyOnLoad(gameObject);
    }

    private void OnEnable()
    {
        GameEvents.OnFinalGame += FinalGameHandle;
    }

    private void OnDisable()
    {
        GameEvents.OnFinalGame -= FinalGameHandle;
    }
    void Start()
    {
        if (panel != null)
        {
            Transform finalTransform = panel.transform.Find("FinalGame");
            if (finalTransform != null)
            {
                textFinal = finalTransform.GetComponent<TextMeshProUGUI>();
            }
            panel.SetActive(false);
        }
    }

    private void FinalGameHandle(bool type)
    {
        StartCoroutine(FinalGameAction(type));
    }

    private IEnumerator FinalGameAction(bool type)
    {
        yield return new WaitForSeconds(2f);
        if (type)
        {
            // WinImage.SetActive(true);
            textFinal.text = "Win Game";
            textFinal.color = Color.green;
        }
        else{
            
            // LoseImage.SetActive(true);
            textFinal.text = "Game Over";
            textFinal.color = Color.red;
        }
        panel.SetActive(true);
    }

    public void OnExitButtonReStartGame()
    {
        Scene currentScene = SceneManager.GetActiveScene();
        SceneManager.LoadScene(currentScene.buildIndex);
    }

    public void ShowCountdownUI(bool show)
    {
        if (countdownUI != null)
            countdownUI.SetActive(show);
    }

    public void UpdateCountdownText(string text)
    {
        if (countdownText != null)
        {
            countdownText.transform.localScale = Vector3.one * 2f;
            countdownText.text = text;
            countdownText.transform
            .DOScale(Vector3.one * 1f, 0.5f) // Nhỏ dần
            .SetEase(Ease.OutBack); // Sử dụng easing hợp lý
        }
            
    }
    
}
