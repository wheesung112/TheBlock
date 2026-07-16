using System.Collections;
using UnityEngine;
using UnityEngine.VFX;

namespace Solodream_BurningPaper
{
    public class BurningPaperController_Random : MonoBehaviour
    {
        [Header("General Control")]
        [SerializeField] private bool _isRandomBurning = false;
        [SerializeField] private bool _isReset = false;
        [SerializeField] private GameObject _paper;
        [SerializeField] private VisualEffect _sparkAsh;

        [Header("Paper Burning Control")]
        [SerializeField] private float _burningArea = 0.0f;
        [SerializeField] private float _burningSpeed = 0.15f;

        [Header("Spark Control")]
        [SerializeField] private float _sparkParticleAmount = 0.0f;
        [SerializeField] private float _sparkSpreadSpeed = 70.0f;

        [Header("Ash Control")]
        [SerializeField] private float _ashParticleAmount = 0.0f;
        [SerializeField] private float _ashSpreadSpeed = 6.0f;

        [Header("Particle Force Control")]
        [SerializeField] private float _noiseIntensity = 0.0f;
        [SerializeField] private float _noiseSpeed = 0.45f;
        [SerializeField] private float _lacunarity = 4.0f;
        [SerializeField] private float _lacunarityMultiplier = 5.0f;

        //For Paper Burning
        private Material _burningMat;

        private const string _verticalBurnBoolParam = "_VerticalBurn";
        private const string _horizontalBurnBoolParam = "_HorizontalBurn";
        private const string _randomBurnAreaParam = "_Random_BurnArea";

        //For Sparh & Ash
        private const string _sparkParticleAmountParam = "SparkParticleAmount";
        private const string _ashParticleAmountParam = "AshParticleAmount";

        //For Force Control
        private const string _noiseIntensityParam = "NoiseIntensity";
        private const string _lacunarityParam = "Lacunarity";

        void Start()
        {
            _burningMat = _paper.GetComponent<MeshRenderer>().material;

            _sparkAsh = _sparkAsh.GetComponent<VisualEffect>();
            _sparkAsh.enabled = false;
        }

        void Update()
        {
            if (_isRandomBurning)
            {
                BurnRandom();
            }

            if (_isReset)
            {
                ResetAll();
            }
        }

        private void BurnRandom()
        {
            //When verticle & horizontal burn is set false, burning set to random burn
            _burningMat.SetInt(_verticalBurnBoolParam, 0);
            _burningMat.SetInt(_horizontalBurnBoolParam, 0);

            if (_burningArea < 1)
            {
                _burningArea += _burningSpeed * Time.deltaTime;
                _burningMat.SetFloat(_randomBurnAreaParam, _burningArea);

                StartCoroutine(WaitForBurn());
            }
            else
            {
                _sparkAsh.Stop();
            }
        }

        private void ResetAll()
        {
            _isRandomBurning = false;
            _burningArea = 0f;
            _burningMat.SetFloat(_randomBurnAreaParam, _burningArea);

            _sparkAsh.Play();
            _sparkAsh.enabled = false;

            _sparkParticleAmount = 0.0f;
            _sparkSpreadSpeed = 70.0f;

            _ashParticleAmount = 0.0f;
            _ashSpreadSpeed = 6.0f;

            _noiseIntensity = 0.0f;
            _noiseSpeed = 0.45f;
            _lacunarity = 4.0f;
            _lacunarityMultiplier = 5.0f;

            _sparkAsh.SetFloat(_sparkParticleAmountParam, _sparkParticleAmount);
            _sparkAsh.SetFloat(_ashParticleAmountParam, _ashParticleAmount);
            _sparkAsh.SetFloat(_noiseIntensityParam, _noiseIntensity);
            _sparkAsh.SetFloat(_lacunarityParam, _lacunarity);

        }

        IEnumerator WaitForBurn()
        {
            yield return new WaitForSeconds(1.65f);
            _sparkAsh.enabled = true;
            if (_burningArea < 1)
            {
                //Spark Part
                if (_sparkParticleAmount < 250)
                {
                    _sparkSpreadSpeed += 100 * Time.deltaTime;
                    _sparkParticleAmount += _sparkSpreadSpeed * Time.deltaTime;
                    _sparkAsh.SetFloat(_sparkParticleAmountParam, _sparkParticleAmount);
                }

                //Ash Part
                if (_ashParticleAmount < 30)
                {
                    _ashSpreadSpeed += 10 * Time.deltaTime;
                    _ashParticleAmount += _ashSpreadSpeed * Time.deltaTime;
                    _sparkAsh.SetFloat(_ashParticleAmountParam, _ashParticleAmount);
                }

                //Force Part
                if (_noiseIntensity < 1.8)
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