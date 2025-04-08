using UnityEngine;
using TMPro;

public class FinalGame : MonoBehaviour
{
    // Start is called before the first frame update
    
    private TextMeshProUGUI textFinal;
    public GameObject panel;

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

        
        if (type)
        {
            textFinal.text = "Win Game";
            textFinal.color = Color.green;
        }
        else{
            textFinal.text = "Game Over";
            textFinal.color = Color.red;
        }
        panel.SetActive(true);
    }
}
