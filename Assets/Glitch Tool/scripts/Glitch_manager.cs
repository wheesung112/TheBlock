using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;

namespace Haipeng.glitch
{
    public class Glitch_manager : MonoBehaviour
    {
        public static Glitch_manager instance;

        [Header("Is initialization successful?")]
        public bool is_initialization_successful;

        [Header("Canvas")]
        public Canvas canvas;

        [Header("Canvas scaler")]
        public CanvasScaler canvas_scaler;

        [Header("camera")]
        public Camera camera_glitch;


        [Header("render_texture")]
        private RenderTexture render_texture;

        [Header("glicth material")]
        private Material material_glitch;


        [Header("material attribute")]
        [ColorUsageAttribute(true, true, 1f, 1f, 1f, 1f)]
        public Color color=Color.white;
        [Range(-500f, 500f)]
        public float glitch_scale = 50;
        [Range(0, 1f)]
        public float glitch_rate = 0.3f;
        [Range(-10, 10f)]
        public float amplitude = 1f;
        [Range(-1f, 1f)]
        public float glitch_x_left = 0.03f;
        [Range(-1f, 1f)]
        public float glitch_x_right = -0.03f;
        [Range(-1f, 1f)]
        public float glitch_y_up = 0;
        [Range(-1f, 1f)]
        public float glitch_y_down = 0;

        void Awake()
        {
            if (Glitch_manager.instance == null)
                Glitch_manager.instance = this;

            int layer_outline_object = LayerMask.NameToLayer("glitch_layer");
            if (layer_outline_object == -1)
            {
                this.is_initialization_successful = false;
                Debug.LogError("Please perform initialization settings first. Just click 'Tools/WuHaipeng / Initialization settings / add layer' in the menu bar.");
            }
            else
            {
                this.is_initialization_successful = true;

                //ser camera priority
                this.camera_glitch.cullingMask = 1 << layer_outline_object;
                this.camera_glitch.depth = Camera.main.depth - 1;


                //set render texture size
                this.render_texture = new RenderTexture(Screen.width, Screen.height, 24);
                this.camera_glitch.targetTexture = this.render_texture;



                //set canvas
                this.canvas.renderMode = RenderMode.ScreenSpaceCamera;
                this.canvas.worldCamera = Camera.main;
                this.canvas_scaler.referenceResolution = new Vector2(Screen.width, Screen.height);

                //get the material, set the main texture
                this.material_glitch = this.canvas.transform.GetChild(0).GetComponent<RawImage>().material;
                this.material_glitch.SetTexture("_Main_texture", this.render_texture);
            }
        }

        void LateUpdate()
        {
            if (this.is_initialization_successful == false)
                return;

            //The camera position is the same as the main camera
            if (this.transform.position != Camera.main.transform.position)
                this.transform.position = Camera.main.transform.position;
            //The camera ratation is the same as the main camera

            if (this.transform.rotation != Camera.main.transform.rotation)
                this.transform.rotation = Camera.main.transform.rotation;

            //The camera field of view is the same as the main camera
            if (this.camera_glitch.fieldOfView != Camera.main.fieldOfView)
                this.camera_glitch.fieldOfView = Camera.main.fieldOfView;


            //set material attribute
            #region 
            if (this.material_glitch.GetColor("_Color") != this.color)
                this.material_glitch.SetColor("_Color", this.color);

            if (this.material_glitch.GetFloat("_glitch_scale") != this.glitch_scale)
                this.material_glitch.SetFloat("_glitch_scale", this.glitch_scale);

            if (this.material_glitch.GetFloat("_glitch_rate") != this.glitch_rate)
                this.material_glitch.SetFloat("_glitch_rate", this.glitch_rate);

            if (this.material_glitch.GetFloat("_amplitude") != this.amplitude)
                this.material_glitch.SetFloat("_amplitude", this.amplitude);

            if (this.material_glitch.GetFloat("_glitch_x_left") != this.glitch_x_left)
                this.material_glitch.SetFloat("_glitch_x_left", this.glitch_x_left);

            if (this.material_glitch.GetFloat("_glitch_x_right") != this.glitch_x_right)
                this.material_glitch.SetFloat("_glitch_x_right", this.glitch_x_right);

            if (this.material_glitch.GetFloat("_glitch_y_up") != this.glitch_y_up)
                this.material_glitch.SetFloat("_glitch_y_up", this.glitch_y_up);

            if (this.material_glitch.GetFloat("_glitch_y_down") != this.glitch_y_down)
                this.material_glitch.SetFloat("_glitch_y_down", this.glitch_y_down);
            #endregion
        }
    }
}
