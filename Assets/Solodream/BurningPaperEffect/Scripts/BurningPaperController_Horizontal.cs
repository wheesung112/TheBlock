using System.Collections;
using UnityEngine;
using UnityEngine.VFX;

namespace Solodream_BurningPaper
{
    public class BurningPaperController_Horizontal : MonoBehaviour
    {
        [Header("General Control")]
        [SerializeField] private bool _isHoriozntalBurning = false;
        [SerializeField] private bool _isReset = false;
        [SerializeField] private GameObject _paper;
        [SerializeField] private VisualEffect _sparkAsh;

        [Header("Paper Burning Control")]
        [SerializeField] private float _burningArea = 0.0f;
        [SerializeField] private float _burningSpeed = 0.15f;

        [Header("Spark & Ash Control")]
        [SerializeField] private float _horiozntalBurnOffset = -4.0f;
        [SerializeField] private float _burnSpreadSpeed = 0.0f;
        [SerializeField] private float _particleSpreadArea = 0.0f;
        [SerializeField] private float _particleSpreadSpeed = 0.01f;

        [Header("Particle Force Control")]
        [SerializeField] private float _noiseIntensity = 0.0f;
        [SerializeField] private float _noiseSpeed = 0.38f;
        [SerializeField] private float _lacunarity = 15.0f;
        [SerializeField] private float _lacunarityMultiplier = -3.0f;

        //For Paper Burning
        private Material _burningMat;

        private const string _horizontalBurnBoolParam = "_HorizontalBurn";
        private const string _horizontalBurnAreaParam = "_Horizontal_BurnArea";

        //For Spark & Ash
        private const string _horizontalBurnOffsetParam = "HorizontalBurnOffset";
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
            if (_isHoriozntalBurning)
            {
                BurnHorizontal();
            }

            if (_isReset)
            {
                ResetAll();
            }
        }

        private void BurnHorizontal()
        {
            _burningMat.SetInt(_horizontalBurnBoolParam, 1);

            if (_burningArea < 1)
            {
                _burningArea += _burningSpeed * Time.deltaTime;
                _burningMat.SetFloat(_horizontalBurnAreaParam, _burningArea);

                StartCoroutine(WaitForBurn());
            }
        }

        private void ResetAll()
        {
            _isHoriozntalBurning = false;
            _burningArea = 0.0f;
            _burningMat.SetFloat(_horizontalBurnAreaParam, _burningArea);

            _horiozntalBurnOffset = -4.0f;
            _burnSpreadSpeed = 0.0f;
            _particleSpreadArea = 0.0f;
            _particleSpreadSpeed = 0.01f;
            _noiseIntensity = 0.0f;
            _noiseSpeed = 0.38f;
            _lacunarityMultiplier = -3.0f;
            _lacunarity = 15.0f;

            _sparkAsh.SetFloat(_horizontalBurnOffsetParam, _horiozntalBurnOffset);
            _sparkAsh.SetFloat(_particleSpreadAreaParam, _particleSpreadArea);
            _sparkAsh.SetFloat(_noiseIntensityParam, _noiseIntensity);
            _sparkAsh.SetFloat(_lacunarityParam, _lacunarity);
        }

        IEnumerator WaitForBurn()
        {
            yield return new WaitForSeconds(0.9f);
            if (_burningArea < 1)
            {
                _burnSpreadSpeed += Time.deltaTime;
                _horiozntalBurnOffset += _burnSpreadSpeed * Time.deltaTime;
                _sparkAsh.SetFloat(_horizontalBurnOffsetParam, _horiozntalBurnOffset);

                if (_particleSpreadArea < 2)
                {
                    _particleSpreadSpeed += Time.deltaTime;
                    _particleSpreadArea += _particleSpreadSpeed * Time.deltaTime;
                    _sparkAsh.SetFloat(_particleSpreadAreaParam, _particleSpreadArea);
                }

                //Force Part
                if (_noiseIntensity < 1.8)
                {
                    _noiseIntensity += _noiseSpeed * Time.deltaTime;
                    _sparkAsh.SetFloat(_noiseIntensityParam, _noiseIntensity);
                }

                if (_lacunarity > 2)
                {
                    _lacunarity += _lacunarityMultiplier * Time.deltaTime;
                    _sparkAsh.SetFloat(_lacunarityParam, _lacunarity);
                }
            }
        }
    }
}