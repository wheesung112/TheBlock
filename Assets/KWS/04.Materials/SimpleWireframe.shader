Shader "Custom/SimpleWireframe"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        
        [Header(Wireframe Settings)]
        _WireColor ("Wire Color", Color) = (0,1,0,1)
        _WireThickness ("Wire Thickness", Range(0, 10)) = 1
        _WireSmoothing ("Wire Smoothing", Range(0, 10)) = 1
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            // Shadow Caster for transparent objects usually requires clipping or handling alpha.
            // If the base is fully transparent, we might NOT want to cast shadows?
            // For now, let's keep it but realize it might cast a solid shadow if we don't custom handle it.
            // Or just allow it (it's wireframe).
            
            ZWrite On
            ZTest LEqual
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f { 
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

        Pass
        {
            Name "SimpleWireframe"
            Tags { "LightMode"="UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 barycentric : TEXCOORD6; // UV7 (w=flag)
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 barycentric : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _BaseColor;
            float _Cutoff;
            float4 _WireColor;
            float _WireThickness;
            float _WireSmoothing;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // Pass Baked Barycentrics
                // If not baked, fallback to (1,1,1) -> Wireframe inactive/solid
                o.barycentric = v.barycentric.w > 0.5 ? v.barycentric.xyz : float3(1,1,1);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Texture Sample with Tint
                fixed4 col = tex2D(_MainTex, i.uv) * _BaseColor;
                
                // Removed clip(col.a - _Cutoff) to allow transparent base

                // Find closest edge distance
                float minBary = min(i.barycentric.x, min(i.barycentric.y, i.barycentric.z));
                
                // Use fwidth for screen-space constant width
                float dist = minBary;
                float edgeWidth = fwidth(dist);
                float lineWeight = _WireThickness * edgeWidth; 
                
                float edge = smoothstep(lineWeight, lineWeight + edgeWidth * _WireSmoothing, dist);
                
                // edge is 0 at wire (keep wire color), 1 at center (keep texture color)
                return lerp(_WireColor, col, edge);
            }
            ENDCG
        }
    }
}
