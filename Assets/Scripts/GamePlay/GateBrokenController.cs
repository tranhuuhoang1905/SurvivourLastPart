using System;
using System.Collections;
using System.Collections.Generic;
using DG.Tweening;
using UnityEngine;

namespace GameNatra
{
    public class GateBrokenController : MonoBehaviour
    {
        [SerializeField] private GameObject mRightObj;
        [SerializeField] private GameObject mLeftObj;

        private void OnEnable()
        {
            Vector3 leftRotation = mLeftObj.transform.localEulerAngles;
            Vector3 rightRotation = mRightObj.transform.localEulerAngles;
            mLeftObj.transform.DOLocalMove(new Vector3(-1.54f, 2.49f, 0), 0.5f);
            mRightObj.transform.DOLocalMove(new Vector3(2f, 2.55f, 0), 0.5f);
            mLeftObj.transform.DOLocalRotate(new Vector3(0, leftRotation.y, -51), 0.5f);
            mRightObj.transform.DOLocalRotate(new Vector3(0, rightRotation.y, 51), 0.5f);
        }
    }
}
