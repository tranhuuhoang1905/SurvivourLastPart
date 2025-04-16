using UnityEngine;
using TMPro;
using UnityEngine.SceneManagement;

using System.Collections;

public class FinalGame : MonoBehaviour
{
    // Start is called before the first frame update
    
    private TextMeshProUGUI textFinal;
    public GameObject panel;
    public GameObject WinImage;
    public GameObject LoseImage;

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
    
}
