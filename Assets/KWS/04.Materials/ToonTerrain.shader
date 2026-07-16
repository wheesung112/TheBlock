Shader "Custom/ToonTerrain"
{
    Properties
    {
        [HideInInspector] _Control("Control (RGBA)", 2D) = "red" {}
        [HideInInspector] _Splat3("Layer 3 (A)", 2D) = "white" {}
        [HideInInspector] _Splat2("Layer 2 (B)", 2D) = "white" {}
        [HideInInspector] _Splat1("Layer 1 (G)", 2D) = "white" {}
        [HideInInspector] _Splat0("Layer 0 (R)", 2D) = "white" {}
        [HideInInspector] _Normal3("Normal 3 (A)", 2D) = "bump" {}
        [HideInInspector] _Normal2("Normal 2 (B)", 2D) = "bump" {}
        [HideInInspector] _Normal1("Normal 1 (G)", 2D) = "bump" {}
        [HideInInspector] _Normal0("Normal 0 (R)", 2D) = "bump" {}
        [HideInInspector] _Smoothness3("Smoothness 3", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _Smoothness2("Smoothness 2", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _Smoothness1("Smoothness 1", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _Smoothness0("Smoothness 0", Range(0.0, 1.0)) = 0.5
        
        // Toon Settings
        [Header(Toon Settings)]
        _ToonRamp ("Toon Ramp Threshold", Range(0, 1)) = 0.5
        _ToonSmoothness ("Toon Ramp Smoothness", Range(0.001, 1)) = 0.05
        _ShadowStrength ("Shadow Strength", Range(0, 1)) = 0.5
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry-100" "RenderPipeline" = "UniversalPipeline" }
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD3;
                float4 shadowCoord : TEXCOORD4;
            };

            // Splatmap Textures
            TEXTURE2D(_Control); SAMPLER(sampler_Control);
            TEXTURE2D(_Splat0); SAMPLER(sampler_Splat0); float4 _Splat0_ST;
            TEXTURE2D(_Splat1); 
            TEXTURE2D(_Splat2); 
            TEXTURE2D(_Splat3); 
            
            TEXTURE2D(_Normal0); 
            TEXTURE2D(_Normal1); 
            TEXTURE2D(_Normal2); 
            TEXTURE2D(_Normal3); 

            CBUFFER_START(UnityPerMaterial)
                float _ToonRamp;
                float _ToonSmoothness;
                float _ShadowStrength;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv = v.uv; // Splatmap UV (Usually untiled)
                
                // Shadows
                o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                // 1. Sample Splatmap Control
                half4 control = SAMPLE_TEXTURE2D(_Control, sampler_Control, i.uv);
                
                // 2. Sample Layers (Tiling is usually handled by Terrain engine transforming UVs, checking...)
                // Terrain engine passes tiled UVs in a specific way or we rely on ST. 
                // For simplicity in this Custom Shader, assuming uniform tiling or using _Splat0_ST for all for now,
                // OR (Correct Way): Compute UVs based on World Pos or specific Tiling props if exposed.
                // Standard Terrain just uses "uv * transform".
                // Let's use WorldXZ for triplanar or just simple scaled UV for now. 
                // Terrain standard shader uses uv with transform.
                
                // Quick Fix: Terrain engine often sets global shader vars or we need property blocks.
                // Let's rely on simple UV * 20 for demo, user can adjust scaling in shader property later.
                float2 tileUV = i.positionWS.xz * 0.2; // Arbitrary scale matching typical terrain
                
                half4 col0 = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, tileUV);
                half4 col1 = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat0, tileUV); // Reuse sampler
                half4 col2 = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat0, tileUV);
                half4 col3 = SAMPLE_TEXTURE2D(_Splat3, sampler_Splat0, tileUV);

                half3 albedo = col0.rgb * control.r + col1.rgb * control.g + col2.rgb * control.b + col3.rgb * control.a;

                // 3. Lighting (Toon)
                Light mainLight = GetMainLight(i.shadowCoord);
                half3 lightDir = normalize(mainLight.direction);
                half3 normal = normalize(i.normalWS);
                
                half NdotL = dot(normal, lightDir);
                
                // Toon Ramp Logic
                half lightIntensity = smoothstep(_ToonRamp - _ToonSmoothness, _ToonRamp + _ToonSmoothness, NdotL);
                
                // Shadows
                half shadow = mainLight.shadowAttenuation;
                half combinedShadow = min(lightIntensity, shadow);
                combinedShadow = lerp(_ShadowStrength, 1.0, combinedShadow);

                half3 finalColor = albedo * (mainLight.color * combinedShadow);
                
                // Ambient
                finalColor += albedo * 0.2; // Simple Ambient

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/InternalErrorShader"
}
