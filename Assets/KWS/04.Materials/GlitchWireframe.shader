Shader "Custom/GlitchWireframe"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (0,0,0,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _EmissionColor ("Emission Color", Color) = (0,0,0,0)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        
        [Header(Glitch Settings)]
        _GlitchAmplitude ("Glitch Amplitude", Range(0, 5)) = 0.5
        _GlitchSpeed ("Glitch Speed", Range(0, 20)) = 5.0
        _GlitchFrequency ("Glitch Frequency", Range(0, 100)) = 10.0
        _GlitchThreshold ("Glitch Threshold", Range(0, 1)) = 0.5
        
        [Header(Wireframe Settings)]
        _WireColor ("Wire Color", Color) = (0,1,1,1)
        _WireThickness ("Wire Thickness", Range(0, 20)) = 2.0
        _WireSmoothing ("Wire Smoothing", Range(0, 10)) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "RenderPipeline"="UniversalPipeline" "Queue"="AlphaTest" }
        LOD 100

        Pass
        {
            Name "GlitchWireframe"
            Tags { "LightMode"="UniversalForward" }
            
            Cull Off 

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma target 4.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 barycentric : TEXCOORD6; // Baked Barycentric [1,0,0,1] (UV7)
                float3 centroidPos : TEXCOORD7; // Baked Triangle Centroid (UV8)
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 barycentric : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _BaseColor;
            float4 _EmissionColor;
            float _Cutoff;
            
            float4 _WireColor;
            float _WireThickness;
            float _WireSmoothing;
            
            float _GlitchAmplitude;
            float _GlitchSpeed;
            float _GlitchFrequency;
            float _GlitchThreshold;

            float random(float3 pos)
            {
                return frac(sin(dot(pos, float3(12.9898, 78.233, 45.543))) * 43758.5453);
            }

            // Vertex Shader
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                // 1. Calculate Noise/Glitch using Centroid (Consistent for whole triangle)
                float3 center = v.centroidPos;
                // Fallback for non-baked meshes: use vertex position (will stretch)
                if(length(center) < 0.001) center = v.vertex.xyz; 
                
                float timeVal = _Time.y * _GlitchSpeed;
                float noiseVal = sin(dot(center, float3(1, 1, 1)) * _GlitchFrequency + timeVal);
                
                float displacement = 0;
                if(abs(noiseVal) > _GlitchThreshold)
                {
                    displacement = noiseVal * _GlitchAmplitude;
                }
                
                // 2. Displace along Face Normal (since it's a split mesh, v.normal IS face normal)
                float3 displacedPos = v.vertex.xyz + v.normal * displacement;
                
                o.vertex = UnityObjectToClipPos(float4(displacedPos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, float4(displacedPos, 1.0)).xyz;
                
                // 3. Pass Baked Barycentrics
                // 3. Pass Baked Barycentrics
                // Check 'w' component flag. If < 0.5, it's unbaked data. Fallback to (1,1,1).
                o.barycentric = v.barycentric.w > 0.5 ? v.barycentric.xyz : float3(1,1,1);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _BaseColor;
                col += _EmissionColor;
                
                float minBary = min(i.barycentric.x, min(i.barycentric.y, i.barycentric.z));
                // Since these are 0..1 values interpolated, standard derivatives work well for specific line widths
                // Or use simple threshold
                // float3 deltas = fwidth(i.barycentric);
                // float3 sm = deltas * _WireSmoothing;
                // float3 th = deltas * _WireThickness;
                // minBary is distance to edge (0 at edge)
                
                // Simple threshold logic from properties
                // NOTE: Without Geom shader pre-scaling, these values are 0..1
                // 1.0 at vertex, 0.5 at edge mid? No.
                // (1,0,0) -> (0,1,0). Midpoint is (0.5, 0.5, 0). Dist to 0 is 0.
                // Wait. Barycentrics: On edge P1-P2, x=0. So minBary=0.
                // So minBary is exactly 0 on the edge.
                
                // We need to scale thickness by fwidth to keep constant screen size
                float dist = minBary;
                // fwidth(dist) gives rate of change per pixel ~ 1/pixels_per_unit
                float edgeWidth = fwidth(dist);
                float lineWeight = _WireThickness * edgeWidth; // pixels
                
                // Smoothstep for AA (Safety epsilon to prevent 0 range)
                float edge = smoothstep(lineWeight, lineWeight + edgeWidth * _WireSmoothing + 0.0001, dist);
                
                // Alpha Clip
                clip(col.a - _Cutoff);

                return lerp(_WireColor, col, edge);
            }
            ENDCG
        }
        
        // ShadowCaster Pass - Essential for realism!
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2g
            {
                float4 vertex : SV_POSITION; // Object space
                float3 worldPos : TEXCOORD1;
                float3 normal : NORMAL;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct g2f
            {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float _GlitchAmplitude;
            float _GlitchSpeed;
            float _GlitchFrequency;
            float _GlitchThreshold;

            v2g vert(appdata v)
            {
                v2g o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }
            
            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
                
                // Setup Stereo Instance for Shadow Caster
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN[0]);
                
                // Replicate displacement logic exactly
                float3 p0 = IN[0].worldPos;
                float3 p1 = IN[1].worldPos;
                float3 p2 = IN[2].worldPos;
                
                float3 center = (p0 + p1 + p2) / 3.0;
                float3 faceNormal = normalize(cross(p1 - p0, p2 - p0));
                
                float timeVal = _Time.y * _GlitchSpeed;
                float noiseVal = sin(dot(center, float3(1, 1, 1)) * _GlitchFrequency + timeVal);
                
                float displacement = 0;
                if(abs(noiseVal) > _GlitchThreshold)
                {
                    displacement = noiseVal * _GlitchAmplitude;
                }
                float3 translation = faceNormal * displacement;

                for(int i=0; i<3; ++i)
                {
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(IN[i], o);

                    float4 displacedWorld = float4(IN[i].worldPos + translation, 1.0);
                    
                    // Manual Shadow Caster Setup since macros assume 'v.vertex' input
                    // But we have world position.
                    // TRANSFER_SHADOW_CASTER_NORMALOFFSET usually handles CLIP space calc.
                    // We need to output CLIP space from Geom.
                    
                    // Unity generic way from World Pos:
                    o.pos = mul(UNITY_MATRIX_VP, displacedWorld);
                    
                    // We also need to handle 'hclip' for bias etc if using standard macros?
                    // V2F_SHADOW_CASTER defines 'pos' (SV_POSITION).
                    // Let's rely on standard MVP transform.
                    
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            float4 frag(g2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
