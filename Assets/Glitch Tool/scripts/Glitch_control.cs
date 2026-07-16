using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Haipeng.glitch
{
    public class Glitch_control : MonoBehaviour
    {
        [Header("Whether to display glitch effect")]
        public bool is_show_glitch_effect;

        private int layer_glitch;
        private int layer_default;

        // Start is called before the first frame update
        void Start()
        {
            this.layer_glitch = LayerMask.NameToLayer("glitch_layer");
            this.layer_default = this.gameObject.layer;
        }

        // Update is called once per frame
        void Update()
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                if (hit.transform.name == this.gameObject.name)
                {
                    if (Input.GetMouseButtonDown(0))
                    {

                        if (Glitch_manager.instance.is_initialization_successful == false)
                        {
                            Debug.LogError("Please perform initialization settings first. Just click 'WuHaipeng / Initialization settings / add layer' in the menu bar.");
                        }
                        else
                        {
                            Audio_manager.instance.play_btn();

                            if (this.is_show_glitch_effect == true)
                            {
                                this.is_show_glitch_effect = false;
                            }
                            else
                            {
                                this.is_show_glitch_effect = true;
                            }
                        }
                    }
                }
            }
        }

        void LateUpdate()
        {
            if (Glitch_manager.instance.is_initialization_successful == false)
                return;

            if (this.is_show_glitch_effect == true)
            {
                if (this.gameObject.layer != this.layer_glitch)
                {
                    this.set_layer(this.transform, this.layer_glitch);
                }
            }
            else
            {
                if (this.gameObject.layer != this.layer_default)
                {
                    this.set_layer(this.transform, this.layer_default);
                }
            }
        }

        private void set_layer(Transform transform, int layer)
        {
            if (transform.childCount > 0)
            {
                for (int i = 0; i < transform.childCount; i++)
                {
                    set_layer(transform.GetChild(i), layer);
                }
                transform.gameObject.layer = layer;
            }
            else
            {
                transform.gameObject.layer = layer;
            }
        }
    }
}