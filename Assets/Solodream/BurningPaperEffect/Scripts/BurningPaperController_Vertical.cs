using System.Collections;
using UnityEngine;
using UnityEngine.VFX;

namespace Solodream_BurningPaper
{
    public class BurningPaperController_Vertical : MonoBehaviour
    {
        [Header("General Control")]
        [SerializeField] private bool _isVerticalBurning = false;
        [SerializeField] private bool _isReset = false;
        [SerializeField] private GameObject _paper;
        [SerializeField] private VisualEffect _sparkAsh;

        [Header("Paper Burning Control")]
        [SerializeField] private float _burningArea = 0f;
        [SerializeField] private float _burningSpeed = 0.15f;

        [Header("Spark & Ash Control")]
        [SerializeField] private float _verticalBurnOffset = -3.4f;
        [SerializeField] private float _burnSpreadSpeed = 0.0f;
        [SerializeField] private float _particleSpreadArea = 0.0f;
        [SerializeField] private float _particleSpreadSpeed = 0.55f;

        [Header("Particle Force Control")]
        [SerializeField] private float _noiseIntensity = 1.5f;
        [SerializeField] private float _noiseSpeed = 0.45f;
        [SerializeField] private float _lacunarity = 4.0f;
        [SerializeField] private float _lacunarityMultiplier = 5.0f;

        //For Paper Burning
        private Material _burningMat;

        private const string _verticalBurnBoolParam = "_VerticalBurn";
        private const string _verticalBurnAreaParam = "_Vertical_BurnArea";

        //For Spark & Ash
        private const string _verticalBurnOffsetParam = "VerticalBurnOffset";
        private const string _particleSpreadAreaParam = "ParticleSpreadArea";

        //For Force Control
        private const string _noiseIntensityParam = "NoiseIntensity";
        private const string _lacunarityParam = "Lacunarity";

        void Start()
        {
            _burningMat = _paper.GetComponent<MeshRenderer>().material;

            _sparkAsh = _sparkAsh.GetComponent<VisualEffect>();
        }

        void Update()
        {
            if (_isVerticalBurning)
            {
                BurnVertical();
            }

            if (_isReset)
            {
                ResetAll();
            }
        }

        private void BurnVertical()
        {
            _burningMat.SetInt(_verticalBurnBoolParam, 1);

            if (_burningArea < 1)
            {
                _burningArea += _burningSpeed * Time.deltaTime;
                _burningMat.SetFloat(_verticalBurnAreaParam, _burningArea);

                StartCoroutine(WaitForBurn());
            }
        }

        private void ResetAll()
        {
            _isVerticalBurning = false;
            _burningArea = 0f;
            _burningMat.SetFloat(_verticalBurnAreaParam, _burningArea);

            _verticalBurnOffset = -3.4f;
            _burnSpreadSpeed = 0.0f;
            _particleSpreadArea = 0.0f;
            _particleSpreadSpeed = 0.55f;
            _noiseIntensity = 1.5f;
            _noiseSpeed = 0.45f;
            _lacunarity = 4.0f;
            _lacunarityMultiplier = 5.0f;

            _sparkAsh.SetFloat(_verticalBurnOffsetParam, _verticalBurnOffset);
            _sparkAsh.SetFloat(_particleSpreadAreaParam, _particleSpreadArea);
            _sparkAsh.SetFloat(_noiseIntensityParam, _noiseIntensity);
            _sparkAsh.SetFloat(_lacunarityParam, _lacunarity);
        }

        IEnumerator WaitForBurn()
        {
            yield return new WaitForSeconds(1.6f);
            if (_burningArea < 1)
            {
                _burnSpreadSpeed += 0.8f * Time.deltaTime;
                _verticalBurnOffset += _burnSpreadSpeed * Time.deltaTime;
                _sparkAsh.SetFloat(_verticalBurnOffsetParam, _verticalBurnOffset);

                if (_particleSpreadArea < 3)
                {
                    _particleSpreadSpeed += 0.4f * Time.deltaTime;
                    _particleSpreadArea += _particleSpreadSpeed * Time.deltaTime;
                    _sparkAsh.SetFloat(_particleSpreadAreaParam, _particleSpreadArea);
                }

                //Force Part
                if (_noiseIntensity < 3f)
                {
                    _noiseIntensity += _noiseSpeed * Time.deltaTime;
                    _sparkAsh.SetFloat(_noiseIntensityParam, _noiseIntensity);
                }

                if (_lacunarity < 12)
                {
                    _lacunarity += _lacunarityMultiplier * Time.deltaTime;
                    _sparkAsh.SetFloat(_lacunarityParam, _lacunarity);
                }
            }
        }
    }
}