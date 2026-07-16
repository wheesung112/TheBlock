// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TriForge/Winter Forest/Bark Double - Tessellation"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_MainTex("Albedo", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_Mask("Smoothness (R), Ambient Occlusion (G), Height (A)", 2D) = "white" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 1
		_HeightMin("Height Min", Range( -2 , 2)) = 0
		_HeightMax("Height Max", Range( -2 , 2)) = 0
		_BottomAlbedo("Bottom Albedo", 2D) = "white" {}
		_BottomNormal("Bottom Normal", 2D) = "bump" {}
		_BottomMask("Bottom Smoothness (R), Ambient Occlusion (G), Height (A)", 2D) = "white" {}
		_BottomSmoothness("Bottom Smoothness", Range( 0 , 1)) = 1
		_BottomHeightMin("Bottom Height Min", Range( -2 , 2)) = 0
		_BottomHeightMax("Bottom Height Max", Range( -2 , 2)) = 1
		_WindStrength("Wind Strength", Range( 0 , 2)) = 0.3
		_WindNoiseScale("Wind Noise Scale", Float) = 1
		_WindSpeed("Wind Speed", Range( 0 , 5)) = 1
		_SnowSmoothness("Snow Smoothness", Range( 0 , 1)) = 1
		_SnowAlbedo("Snow Albedo", 2D) = "white" {}
		_SnowNormal("Snow Normal", 2D) = "bump" {}
		_SnowAmount("Snow Amount", Range( 0 , 2)) = 0
		_SnowMaskSharpness("Snow Mask Sharpness", Range( 0 , 3)) = 1
		_DisplacementStrength("Displacement Strength", Float) = 1
		_TessellationSeamOffset("Tessellation Seam Offset", Range( -3 , 3)) = 0
		_TessellationSeamMask("Tessellation Seam Mask", Range( 0.1 , 5)) = 3
		_BlendStrength("Blend Strength", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _texcoord3( "", 2D ) = "white" {}


		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		_TessValue( "Max Tessellation", Range( 1, 32 ) ) = 16
		_TessMin( "Tess Min Distance", Float ) = 10
		_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Lit" }

		Cull Back
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			
			
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
		
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _FORWARD_PLUS

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_TANGENT
			#define ASE_NEEDS_FRAG_WORLD_BITANGENT
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;
			TEXTURE2D(_MainTex);
			TEXTURE2D(_BottomAlbedo);
			TEXTURE2D(_SnowAlbedo);
			TEXTURE2D(_Normal);
			TEXTURE2D(_BottomNormal);
			TEXTURE2D(_SnowNormal);
			float TFW_SnowAmount;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 uv_Mask = v.texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				
				o.ase_texcoord8.xy = v.texcoord.xy;
				o.ase_texcoord8.zw = v.texcoord2.xy;
				o.ase_color = v.ase_color;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif
				v.normalOS = v.normalOS;
				v.tangentOS = v.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( v.normalOS, v.tangentOS );

				o.tSpace0 = float4( normalInput.normalWS, vertexInput.positionWS.x );
				o.tSpace1 = float4( normalInput.tangentWS, vertexInput.positionWS.y );
				o.tSpace2 = float4( normalInput.bitangentWS, vertexInput.positionWS.z );

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord.xy;
					o.lightmapUVOrVertexSH.xy = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( vertexInput.positionWS, normalInput.normalWS );

				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( vertexInput.positionCS.z );
				#else
					half fogFactor = 0;
				#endif

				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = vertexInput.positionCS;
				o.clipPosV = vertexInput.positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.tangentOS = v.tangentOS;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionCS);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 uv_MainTex = IN.ase_texcoord8.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 Albedo162 = SAMPLE_TEXTURE2D( _MainTex, sampler_Trilinear_Repeat_Aniso16, uv_MainTex );
				float2 uv2_BottomAlbedo = IN.ase_texcoord8.zw * _BottomAlbedo_ST.xy + _BottomAlbedo_ST.zw;
				float4 BottomAlbedo268 = SAMPLE_TEXTURE2D( _BottomAlbedo, sampler_Trilinear_Repeat_Aniso16, uv2_BottomAlbedo );
				float2 uv_Mask = IN.ase_texcoord8.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*IN.ase_color.r)*4)+(IN.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float4 lerpResult286 = lerp( Albedo162 , BottomAlbedo268 , TopBottomMask283);
				float4 AlbedoBottomBlend288 = lerpResult286;
				float2 uv_SnowAlbedo = IN.ase_texcoord8.xy * _SnowAlbedo_ST.xy + _SnowAlbedo_ST.zw;
				float4 tex2DNode385 = SAMPLE_TEXTURE2D( _SnowAlbedo, sampler_Trilinear_Repeat_Aniso16, uv_SnowAlbedo );
				float4 SnowAlbedo195 = tex2DNode385;
				float2 uv_Normal = IN.ase_texcoord8.xy * _Normal_ST.xy + _Normal_ST.zw;
				float3 NormalMap163 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal, sampler_Trilinear_Repeat_Aniso16, uv_Normal ), 1.0f );
				float2 uv2_BottomNormal = IN.ase_texcoord8.zw * _BottomNormal_ST.xy + _BottomNormal_ST.zw;
				float3 BottomNormal269 = UnpackNormalScale( SAMPLE_TEXTURE2D( _BottomNormal, sampler_Trilinear_Repeat_Aniso16, uv2_BottomNormal ), 1.0f );
				float3 lerpResult297 = lerp( NormalMap163 , BottomNormal269 , TopBottomMask283);
				float3 NormalBottomBlend299 = lerpResult297;
				float2 uv_SnowNormal = IN.ase_texcoord8.xy * _SnowNormal_ST.xy + _SnowNormal_ST.zw;
				float3 SnowNormal178 = UnpackNormalScale( SAMPLE_TEXTURE2D( _SnowNormal, sampler_Trilinear_Repeat_Aniso16, uv_SnowNormal ), 1.0f );
				float temp_output_450_0 = ( _SnowAmount * TFW_SnowAmount );
				float3 lerpResult185 = lerp( NormalBottomBlend299 , SnowNormal178 , saturate( ( pow( WorldNormal.y , 10.0 ) * temp_output_450_0 ) ));
				float3 tanToWorld0 = float3( WorldTangent.x, WorldBiTangent.x, WorldNormal.x );
				float3 tanToWorld1 = float3( WorldTangent.y, WorldBiTangent.y, WorldNormal.y );
				float3 tanToWorld2 = float3( WorldTangent.z, WorldBiTangent.z, WorldNormal.z );
				float3 tanNormal187 = lerpResult185;
				float3 worldNormal187 = float3(dot(tanToWorld0,tanNormal187), dot(tanToWorld1,tanNormal187), dot(tanToWorld2,tanNormal187));
				float SnowBlendMask192 = saturate( pow( ( saturate( worldNormal187.y ) * temp_output_450_0 ) , _SnowMaskSharpness ) );
				float4 lerpResult197 = lerp( AlbedoBottomBlend288 , SnowAlbedo195 , SnowBlendMask192);
				float4 FinalAlbedo200 = lerpResult197;
				
				float3 NormalBlend186 = lerpResult185;
				
				float Smoothness167 = ( tex2DNode106.r * _Smoothness );
				float2 uv2_BottomMask = IN.ase_texcoord8.zw * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask );
				float BottomSmoothness310 = ( tex2DNode263.r * _BottomSmoothness );
				float lerpResult317 = lerp( Smoothness167 , BottomSmoothness310 , TopBottomMask283);
				float SmoothnessBottomBlend318 = lerpResult317;
				float SnowSmoothness205 = ( tex2DNode385.a * _SnowSmoothness );
				float lerpResult207 = lerp( SmoothnessBottomBlend318 , SnowSmoothness205 , SnowBlendMask192);
				float FinalSmoothness208 = lerpResult207;
				
				float AmbientOcclusion165 = tex2DNode106.g;
				float BottomAO311 = tex2DNode263.g;
				float lerpResult325 = lerp( AmbientOcclusion165 , BottomAO311 , TopBottomMask283);
				float AOBlend326 = lerpResult325;
				float lerpResult209 = lerp( AOBlend326 , 1.0 , SnowBlendMask192);
				float FinalAmbientOcclusion213 = lerpResult209;
				

				float3 BaseColor = FinalAlbedo200.rgb;
				float3 Normal = NormalBlend186;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = FinalSmoothness208;
				float Occlusion = FinalAmbientOcclusion213;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif

				#ifdef _CLEARCOAT
					float CoatMask = 0;
					float CoatSmoothness = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;

				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));
						#elif _NORMAL_DROPOFF_OS
							inputData.normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							inputData.normalWS = Normal;
						#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = ShadowCoords;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif
					inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
					#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;

				#ifdef _CLEARCOAT
					surfaceData.clearCoatMask       = saturate(CoatMask);
					surfaceData.clearCoatSmoothness = saturate(CoatSmoothness);
				#endif

				#ifdef _DBUFFER
					ApplyDecalToSurfaceData(IN.positionCS, surfaceData, inputData);
				#endif

				half4 color = UniversalFragmentPBR( inputData, surfaceData);

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;

					#define SUM_LIGHT_TRANSMISSION(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 transmission = max( 0, -dot( inputData.normalWS, Light.direction ) ) * atten * Transmission;\
						color.rgb += BaseColor * transmission;

					SUM_LIGHT_TRANSMISSION( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSMISSION( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSMISSION( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#define SUM_LIGHT_TRANSLUCENCY(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 lightDir = Light.direction + inputData.normalWS * normal;\
						half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );\
						half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;\
						color.rgb += BaseColor * translucency * strength;

					SUM_LIGHT_TRANSLUCENCY( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSLUCENCY( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSLUCENCY( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_REFRACTION
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal,0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD2;
				#endif				
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float2 uv_Mask = v.ase_texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.ase_texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.ase_texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir(v.normalOS);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD2;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 uv_Mask = v.ase_texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.ase_texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.ase_texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = vertexInput.positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = vertexInput.positionCS;
				o.clipPosV = vertexInput.positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature EDITOR_VISUALIZATION

			#define SHADERPASS SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef EDITOR_VISUALIZATION
					float4 VizUV : TEXCOORD2;
					float4 LightCoord : TEXCOORD3;
				#endif
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;
			TEXTURE2D(_MainTex);
			TEXTURE2D(_BottomAlbedo);
			TEXTURE2D(_SnowAlbedo);
			TEXTURE2D(_Normal);
			TEXTURE2D(_BottomNormal);
			TEXTURE2D(_SnowNormal);
			float TFW_SnowAmount;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 uv_Mask = v.texcoord0.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord6.xyz = ase_worldTangent;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord7.xyz = ase_worldBitangent;
				
				o.ase_texcoord4.xy = v.texcoord0.xy;
				o.ase_texcoord4.zw = v.texcoord2.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				o.ase_texcoord7.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				o.positionCS = MetaVertexPosition( v.positionOS, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );

				#ifdef EDITOR_VISUALIZATION
					float2 VizUV = 0;
					float4 LightCoord = 0;
					UnityEditorVizData(v.positionOS.xyz, v.texcoord0.xy, v.texcoord1.xy, v.texcoord2.xy, VizUV, LightCoord);
					o.VizUV = float4(VizUV, 0, 0);
					o.LightCoord = LightCoord;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.texcoord0 = v.texcoord0;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.texcoord0 = patch[0].texcoord0 * bary.x + patch[1].texcoord0 * bary.y + patch[2].texcoord0 * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_MainTex = IN.ase_texcoord4.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 Albedo162 = SAMPLE_TEXTURE2D( _MainTex, sampler_Trilinear_Repeat_Aniso16, uv_MainTex );
				float2 uv2_BottomAlbedo = IN.ase_texcoord4.zw * _BottomAlbedo_ST.xy + _BottomAlbedo_ST.zw;
				float4 BottomAlbedo268 = SAMPLE_TEXTURE2D( _BottomAlbedo, sampler_Trilinear_Repeat_Aniso16, uv2_BottomAlbedo );
				float2 uv_Mask = IN.ase_texcoord4.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*IN.ase_color.r)*4)+(IN.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float4 lerpResult286 = lerp( Albedo162 , BottomAlbedo268 , TopBottomMask283);
				float4 AlbedoBottomBlend288 = lerpResult286;
				float2 uv_SnowAlbedo = IN.ase_texcoord4.xy * _SnowAlbedo_ST.xy + _SnowAlbedo_ST.zw;
				float4 tex2DNode385 = SAMPLE_TEXTURE2D( _SnowAlbedo, sampler_Trilinear_Repeat_Aniso16, uv_SnowAlbedo );
				float4 SnowAlbedo195 = tex2DNode385;
				float2 uv_Normal = IN.ase_texcoord4.xy * _Normal_ST.xy + _Normal_ST.zw;
				float3 NormalMap163 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal, sampler_Trilinear_Repeat_Aniso16, uv_Normal ), 1.0f );
				float2 uv2_BottomNormal = IN.ase_texcoord4.zw * _BottomNormal_ST.xy + _BottomNormal_ST.zw;
				float3 BottomNormal269 = UnpackNormalScale( SAMPLE_TEXTURE2D( _BottomNormal, sampler_Trilinear_Repeat_Aniso16, uv2_BottomNormal ), 1.0f );
				float3 lerpResult297 = lerp( NormalMap163 , BottomNormal269 , TopBottomMask283);
				float3 NormalBottomBlend299 = lerpResult297;
				float2 uv_SnowNormal = IN.ase_texcoord4.xy * _SnowNormal_ST.xy + _SnowNormal_ST.zw;
				float3 SnowNormal178 = UnpackNormalScale( SAMPLE_TEXTURE2D( _SnowNormal, sampler_Trilinear_Repeat_Aniso16, uv_SnowNormal ), 1.0f );
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float temp_output_450_0 = ( _SnowAmount * TFW_SnowAmount );
				float3 lerpResult185 = lerp( NormalBottomBlend299 , SnowNormal178 , saturate( ( pow( ase_worldNormal.y , 10.0 ) * temp_output_450_0 ) ));
				float3 ase_worldTangent = IN.ase_texcoord6.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord7.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal187 = lerpResult185;
				float3 worldNormal187 = float3(dot(tanToWorld0,tanNormal187), dot(tanToWorld1,tanNormal187), dot(tanToWorld2,tanNormal187));
				float SnowBlendMask192 = saturate( pow( ( saturate( worldNormal187.y ) * temp_output_450_0 ) , _SnowMaskSharpness ) );
				float4 lerpResult197 = lerp( AlbedoBottomBlend288 , SnowAlbedo195 , SnowBlendMask192);
				float4 FinalAlbedo200 = lerpResult197;
				

				float3 BaseColor = FinalAlbedo200.rgb;
				float3 Emission = 0;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = BaseColor;
				metaInput.Emission = Emission;
				#ifdef EDITOR_VISUALIZATION
					metaInput.VizUV = IN.VizUV.xy;
					metaInput.LightCoord = IN.LightCoord;
				#endif

				return UnityMetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;
			TEXTURE2D(_MainTex);
			TEXTURE2D(_BottomAlbedo);
			TEXTURE2D(_SnowAlbedo);
			TEXTURE2D(_Normal);
			TEXTURE2D(_BottomNormal);
			TEXTURE2D(_SnowNormal);
			float TFW_SnowAmount;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float2 uv_Mask = v.ase_texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.ase_texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.ase_texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord3.xyz = ase_worldNormal;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord2.zw = v.ase_texcoord2.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = vertexInput.positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = vertexInput.positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_MainTex = IN.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 Albedo162 = SAMPLE_TEXTURE2D( _MainTex, sampler_Trilinear_Repeat_Aniso16, uv_MainTex );
				float2 uv2_BottomAlbedo = IN.ase_texcoord2.zw * _BottomAlbedo_ST.xy + _BottomAlbedo_ST.zw;
				float4 BottomAlbedo268 = SAMPLE_TEXTURE2D( _BottomAlbedo, sampler_Trilinear_Repeat_Aniso16, uv2_BottomAlbedo );
				float2 uv_Mask = IN.ase_texcoord2.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*IN.ase_color.r)*4)+(IN.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float4 lerpResult286 = lerp( Albedo162 , BottomAlbedo268 , TopBottomMask283);
				float4 AlbedoBottomBlend288 = lerpResult286;
				float2 uv_SnowAlbedo = IN.ase_texcoord2.xy * _SnowAlbedo_ST.xy + _SnowAlbedo_ST.zw;
				float4 tex2DNode385 = SAMPLE_TEXTURE2D( _SnowAlbedo, sampler_Trilinear_Repeat_Aniso16, uv_SnowAlbedo );
				float4 SnowAlbedo195 = tex2DNode385;
				float2 uv_Normal = IN.ase_texcoord2.xy * _Normal_ST.xy + _Normal_ST.zw;
				float3 NormalMap163 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal, sampler_Trilinear_Repeat_Aniso16, uv_Normal ), 1.0f );
				float2 uv2_BottomNormal = IN.ase_texcoord2.zw * _BottomNormal_ST.xy + _BottomNormal_ST.zw;
				float3 BottomNormal269 = UnpackNormalScale( SAMPLE_TEXTURE2D( _BottomNormal, sampler_Trilinear_Repeat_Aniso16, uv2_BottomNormal ), 1.0f );
				float3 lerpResult297 = lerp( NormalMap163 , BottomNormal269 , TopBottomMask283);
				float3 NormalBottomBlend299 = lerpResult297;
				float2 uv_SnowNormal = IN.ase_texcoord2.xy * _SnowNormal_ST.xy + _SnowNormal_ST.zw;
				float3 SnowNormal178 = UnpackNormalScale( SAMPLE_TEXTURE2D( _SnowNormal, sampler_Trilinear_Repeat_Aniso16, uv_SnowNormal ), 1.0f );
				float3 ase_worldNormal = IN.ase_texcoord3.xyz;
				float temp_output_450_0 = ( _SnowAmount * TFW_SnowAmount );
				float3 lerpResult185 = lerp( NormalBottomBlend299 , SnowNormal178 , saturate( ( pow( ase_worldNormal.y , 10.0 ) * temp_output_450_0 ) ));
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal187 = lerpResult185;
				float3 worldNormal187 = float3(dot(tanToWorld0,tanNormal187), dot(tanToWorld1,tanNormal187), dot(tanToWorld2,tanNormal187));
				float SnowBlendMask192 = saturate( pow( ( saturate( worldNormal187.y ) * temp_output_450_0 ) , _SnowMaskSharpness ) );
				float4 lerpResult197 = lerp( AlbedoBottomBlend288 , SnowAlbedo195 , SnowBlendMask192);
				float4 FinalAlbedo200 = lerpResult197;
				

				float3 BaseColor = FinalAlbedo200.rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				half4 color = half4(BaseColor, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			Blend One Zero
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldTangent : TEXCOORD2;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD3;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD4;
				#endif
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;
			TEXTURE2D(_Normal);
			TEXTURE2D(_BottomNormal);
			TEXTURE2D(_SnowNormal);
			float TFW_SnowAmount;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 uv_Mask = v.ase_texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.ase_texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.ase_texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				
				o.ase_texcoord5.xy = v.ase_texcoord.xy;
				o.ase_texcoord5.zw = v.ase_texcoord2.xy;
				o.ase_color = v.ase_color;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;
				v.tangentOS = v.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );

				float3 normalWS = TransformObjectToWorldNormal( v.normalOS );
				float4 tangentWS = float4( TransformObjectToWorldDir( v.tangentOS.xyz ), v.tangentOS.w );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = vertexInput.positionWS;
				#endif

				o.worldNormal = normalWS;
				o.worldTangent = tangentWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = vertexInput.positionCS;
				o.clipPosV = vertexInput.positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.tangentOS = v.tangentOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag(	VertexOutput IN
						, out half4 outNormalWS : SV_Target0
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float3 WorldNormal = IN.worldNormal;
				float4 WorldTangent = IN.worldTangent;

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_Normal = IN.ase_texcoord5.xy * _Normal_ST.xy + _Normal_ST.zw;
				float3 NormalMap163 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal, sampler_Trilinear_Repeat_Aniso16, uv_Normal ), 1.0f );
				float2 uv2_BottomNormal = IN.ase_texcoord5.zw * _BottomNormal_ST.xy + _BottomNormal_ST.zw;
				float3 BottomNormal269 = UnpackNormalScale( SAMPLE_TEXTURE2D( _BottomNormal, sampler_Trilinear_Repeat_Aniso16, uv2_BottomNormal ), 1.0f );
				float2 uv_Mask = IN.ase_texcoord5.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*IN.ase_color.r)*4)+(IN.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float3 lerpResult297 = lerp( NormalMap163 , BottomNormal269 , TopBottomMask283);
				float3 NormalBottomBlend299 = lerpResult297;
				float2 uv_SnowNormal = IN.ase_texcoord5.xy * _SnowNormal_ST.xy + _SnowNormal_ST.zw;
				float3 SnowNormal178 = UnpackNormalScale( SAMPLE_TEXTURE2D( _SnowNormal, sampler_Trilinear_Repeat_Aniso16, uv_SnowNormal ), 1.0f );
				float temp_output_450_0 = ( _SnowAmount * TFW_SnowAmount );
				float3 lerpResult185 = lerp( NormalBottomBlend299 , SnowNormal178 , saturate( ( pow( WorldNormal.y , 10.0 ) * temp_output_450_0 ) ));
				float3 NormalBlend186 = lerpResult185;
				

				float3 Normal = NormalBlend186;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(WorldNormal);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float crossSign = (WorldTangent.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
							float3 bitangent = crossSign * cross(WorldNormal.xyz, WorldTangent.xyz);
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent.xyz, bitangent, WorldNormal.xyz));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = WorldNormal;
					#endif
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "GBuffer"
			Tags { "LightMode"="UniversalGBuffer" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			
			
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
		
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_GBUFFER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif
			
			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_TANGENT
			#define ASE_NEEDS_FRAG_WORLD_BITANGENT
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
				float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;
			TEXTURE2D(_MainTex);
			TEXTURE2D(_BottomAlbedo);
			TEXTURE2D(_SnowAlbedo);
			TEXTURE2D(_Normal);
			TEXTURE2D(_BottomNormal);
			TEXTURE2D(_SnowNormal);
			float TFW_SnowAmount;


			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 uv_Mask = v.texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				
				o.ase_texcoord8.xy = v.texcoord.xy;
				o.ase_texcoord8.zw = v.texcoord2.xy;
				o.ase_color = v.ase_color;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;
				v.tangentOS = v.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( v.normalOS, v.tangentOS );

				o.tSpace0 = float4( normalInput.normalWS, vertexInput.positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, vertexInput.positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, vertexInput.positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy);
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH(normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz);
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord.xy;
					o.lightmapUVOrVertexSH.xy = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( vertexInput.positionWS, normalInput.normalWS );

				o.fogFactorAndVertexLight = half4(0, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = vertexInput.positionCS;
				o.clipPosV = vertexInput.positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.tangentOS = v.tangentOS;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			FragmentOutput frag ( VertexOutput IN
								#ifdef ASE_DEPTH_WRITE_ON
								,out float outputDepth : ASE_SV_DEPTH
								#endif
								 )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionCS);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#else
					ShadowCoords = float4(0, 0, 0, 0);
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 uv_MainTex = IN.ase_texcoord8.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 Albedo162 = SAMPLE_TEXTURE2D( _MainTex, sampler_Trilinear_Repeat_Aniso16, uv_MainTex );
				float2 uv2_BottomAlbedo = IN.ase_texcoord8.zw * _BottomAlbedo_ST.xy + _BottomAlbedo_ST.zw;
				float4 BottomAlbedo268 = SAMPLE_TEXTURE2D( _BottomAlbedo, sampler_Trilinear_Repeat_Aniso16, uv2_BottomAlbedo );
				float2 uv_Mask = IN.ase_texcoord8.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*IN.ase_color.r)*4)+(IN.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float4 lerpResult286 = lerp( Albedo162 , BottomAlbedo268 , TopBottomMask283);
				float4 AlbedoBottomBlend288 = lerpResult286;
				float2 uv_SnowAlbedo = IN.ase_texcoord8.xy * _SnowAlbedo_ST.xy + _SnowAlbedo_ST.zw;
				float4 tex2DNode385 = SAMPLE_TEXTURE2D( _SnowAlbedo, sampler_Trilinear_Repeat_Aniso16, uv_SnowAlbedo );
				float4 SnowAlbedo195 = tex2DNode385;
				float2 uv_Normal = IN.ase_texcoord8.xy * _Normal_ST.xy + _Normal_ST.zw;
				float3 NormalMap163 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal, sampler_Trilinear_Repeat_Aniso16, uv_Normal ), 1.0f );
				float2 uv2_BottomNormal = IN.ase_texcoord8.zw * _BottomNormal_ST.xy + _BottomNormal_ST.zw;
				float3 BottomNormal269 = UnpackNormalScale( SAMPLE_TEXTURE2D( _BottomNormal, sampler_Trilinear_Repeat_Aniso16, uv2_BottomNormal ), 1.0f );
				float3 lerpResult297 = lerp( NormalMap163 , BottomNormal269 , TopBottomMask283);
				float3 NormalBottomBlend299 = lerpResult297;
				float2 uv_SnowNormal = IN.ase_texcoord8.xy * _SnowNormal_ST.xy + _SnowNormal_ST.zw;
				float3 SnowNormal178 = UnpackNormalScale( SAMPLE_TEXTURE2D( _SnowNormal, sampler_Trilinear_Repeat_Aniso16, uv_SnowNormal ), 1.0f );
				float temp_output_450_0 = ( _SnowAmount * TFW_SnowAmount );
				float3 lerpResult185 = lerp( NormalBottomBlend299 , SnowNormal178 , saturate( ( pow( WorldNormal.y , 10.0 ) * temp_output_450_0 ) ));
				float3 tanToWorld0 = float3( WorldTangent.x, WorldBiTangent.x, WorldNormal.x );
				float3 tanToWorld1 = float3( WorldTangent.y, WorldBiTangent.y, WorldNormal.y );
				float3 tanToWorld2 = float3( WorldTangent.z, WorldBiTangent.z, WorldNormal.z );
				float3 tanNormal187 = lerpResult185;
				float3 worldNormal187 = float3(dot(tanToWorld0,tanNormal187), dot(tanToWorld1,tanNormal187), dot(tanToWorld2,tanNormal187));
				float SnowBlendMask192 = saturate( pow( ( saturate( worldNormal187.y ) * temp_output_450_0 ) , _SnowMaskSharpness ) );
				float4 lerpResult197 = lerp( AlbedoBottomBlend288 , SnowAlbedo195 , SnowBlendMask192);
				float4 FinalAlbedo200 = lerpResult197;
				
				float3 NormalBlend186 = lerpResult185;
				
				float Smoothness167 = ( tex2DNode106.r * _Smoothness );
				float2 uv2_BottomMask = IN.ase_texcoord8.zw * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask );
				float BottomSmoothness310 = ( tex2DNode263.r * _BottomSmoothness );
				float lerpResult317 = lerp( Smoothness167 , BottomSmoothness310 , TopBottomMask283);
				float SmoothnessBottomBlend318 = lerpResult317;
				float SnowSmoothness205 = ( tex2DNode385.a * _SnowSmoothness );
				float lerpResult207 = lerp( SmoothnessBottomBlend318 , SnowSmoothness205 , SnowBlendMask192);
				float FinalSmoothness208 = lerpResult207;
				
				float AmbientOcclusion165 = tex2DNode106.g;
				float BottomAO311 = tex2DNode263.g;
				float lerpResult325 = lerp( AmbientOcclusion165 , BottomAO311 , TopBottomMask283);
				float AOBlend326 = lerpResult325;
				float lerpResult209 = lerp( AOBlend326 , 1.0 , SnowBlendMask192);
				float FinalAmbientOcclusion213 = lerpResult209;
				

				float3 BaseColor = FinalAlbedo200.rgb;
				float3 Normal = NormalBlend186;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = FinalSmoothness208;
				float Occlusion = FinalAmbientOcclusion213;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.positionCS = IN.positionCS;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
						inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
						inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
						inputData.normalWS = Normal;
					#endif
				#else
					inputData.normalWS = WorldNormal;
				#endif

				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				inputData.viewDirectionWS = SafeNormalize( WorldViewDirection );

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#else
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
					#else
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
					#endif
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
						#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				#ifdef _DBUFFER
					ApplyDecal(IN.positionCS,
						BaseColor,
						Specular,
						inputData.normalWS,
						Metallic,
						Occlusion,
						Smoothness);
				#endif

				BRDFData brdfData;
				InitializeBRDFData
				(BaseColor, Metallic, Specular, Smoothness, Alpha, brdfData);

				Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
				half4 color;
				MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
				color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, Occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
				color.a = Alpha;

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return BRDFDataToGbuffer(brdfData, inputData, Smoothness, Emission + color.rgb, Occlusion);
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

			#define SCENESELECTIONPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 uv_Mask = v.ase_texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.ase_texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.ase_texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

		    #define SCENEPICKINGPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Mask_ST;
			float4 _BottomMask_ST;
			float4 _SnowNormal_ST;
			float4 _BottomNormal_ST;
			float4 _Normal_ST;
			float4 _SnowAlbedo_ST;
			float4 _BottomAlbedo_ST;
			float4 _MainTex_ST;
			float _Smoothness;
			float _SnowMaskSharpness;
			float _SnowAmount;
			float _WindStrength;
			float _WindNoiseScale;
			float _WindSpeed;
			float _DisplacementStrength;
			float _TessellationSeamMask;
			float _TessellationSeamOffset;
			float _BlendStrength;
			float _BottomHeightMax;
			float _BottomHeightMin;
			float _HeightMax;
			float _HeightMin;
			float _BottomSmoothness;
			float _SnowSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			float TFW_WindStrength;
			int TFW_EnableWind;
			TEXTURE2D(_Mask);
			SAMPLER(sampler_Trilinear_Repeat_Aniso16);
			TEXTURE2D(_BottomMask);
			float3 TFW_WindDirection;
			float TFW_DirectionRandomness;
			float TFW_WindSpeed;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 uv_Mask = v.ase_texcoord.xy * _Mask_ST.xy + _Mask_ST.zw;
				float4 tex2DNode106 = SAMPLE_TEXTURE2D_LOD( _Mask, sampler_Trilinear_Repeat_Aniso16, uv_Mask, 0.0 );
				float temp_output_134_0 = (_HeightMin + (tex2DNode106.a - 0.0) * (_HeightMax - _HeightMin) / (1.0 - 0.0));
				float HeightMap265 = temp_output_134_0;
				float2 uv2_BottomMask = v.ase_texcoord2.xy * _BottomMask_ST.xy + _BottomMask_ST.zw;
				float4 tex2DNode263 = SAMPLE_TEXTURE2D_LOD( _BottomMask, sampler_Trilinear_Repeat_Aniso16, uv2_BottomMask, 0.0 );
				float BottomHeight272 = (_BottomHeightMin + (tex2DNode263.a - 0.0) * (_BottomHeightMax - _BottomHeightMin) / (1.0 - 0.0));
				float HeightMask282 = saturate(pow(max( (((( HeightMap265 * 20.0 )*v.ase_color.r)*4)+(v.ase_color.r*2)), 0 ),_BlendStrength));
				float TopBottomMask283 = HeightMask282;
				float lerpResult303 = lerp( HeightMap265 , BottomHeight272 , TopBottomMask283);
				float HeightBottomBlend304 = lerpResult303;
				float saferPower155 = abs( v.ase_color.b );
				float lerpResult153 = lerp( HeightBottomBlend304 , _TessellationSeamOffset , pow( saferPower155 , _TessellationSeamMask ));
				float3 HeightDisplacement169 = ( ( ( lerpResult153 * _DisplacementStrength ) * v.normalOS ) * ( 1.0 - v.ase_color.g ) );
				float2 texCoord36 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float saferPower68 = abs( texCoord36.y );
				float ifLocalVar109_g1 = 0;
				if( abs( TFW_WindDirection.x ) > 0.0 )
				ifLocalVar109_g1 = 1.0;
				else if( abs( TFW_WindDirection.x ) == 0.0 )
				ifLocalVar109_g1 = 0.0;
				float ifLocalVar110_g1 = 0;
				if( abs( TFW_WindDirection.z ) > 0.0 )
				ifLocalVar110_g1 = 0.0;
				float ifLocalVar112_g1 = 0;
				if( ifLocalVar109_g1 == ifLocalVar110_g1 )
				ifLocalVar112_g1 = 1.0;
				float3 lerpResult123_g1 = lerp( TFW_WindDirection , float3(1,0,0) , ifLocalVar112_g1);
				float3 worldToObjDir38_g1 = normalize( mul( GetWorldToObjectMatrix(), float4( lerpResult123_g1, 0 ) ).xyz );
				float3 lerpResult39_g1 = lerp( worldToObjDir38_g1 , TFW_WindDirection , TFW_DirectionRandomness);
				float3 WindDirection41_g1 = lerpResult39_g1;
				float WindSpeed19_g1 = ( _WindSpeed * TFW_WindSpeed );
				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				float4 transform2_g1 = mul(GetWorldToObjectMatrix(),float4( ase_worldPos , 0.0 ));
				float2 WorldSpaceUv9_g1 = (( transform2_g1 / ( -100.0 * ( 1.0 * _WindNoiseScale ) ) )).xz;
				float2 texCoord12_g1 = v.ase_texcoord1.xy * float2( 0,0 ) + WorldSpaceUv9_g1;
				float2 temp_cast_1 = (texCoord12_g1.x).xx;
				float2 panner13_g1 = ( 1.0 * _Time.y * ( float2( 0.12,0 ) * WindSpeed19_g1 ) + temp_cast_1);
				float simplePerlin3D11_g1 = snoise( float3( panner13_g1 ,  0.0 )*0.5 );
				float MainWindBending86_g1 = simplePerlin3D11_g1;
				float WindRotation32_g1 = radians( ( ( (-0.6 + (MainWindBending86_g1 - -1.0) * (1.0 - -0.6) / (1.0 - -1.0)) * TFW_WindStrength ) * 25.0 ) );
				float3 rotatedValue42_g1 = RotateAroundAxis( float3( 0,0,0 ), v.positionOS.xyz, WindDirection41_g1, WindRotation32_g1 );
				float3 MainWind168 = ( ( saturate( pow( saferPower68 , 2.34 ) ) * ( ( rotatedValue42_g1 - v.positionOS.xyz ) * TFW_EnableWind ) ) * _WindStrength );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( HeightDisplacement169 + MainWind168 );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
						clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraphLitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback "Hidden/InternalErrorShader"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.CommentaryNode;160;-4249.747,1363.948;Inherit;False;1889.651;1137.943;;6;39;38;77;6;33;168;Main Wind;0.7133185,0.4198113,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;259;-4699.391,-5664.448;Inherit;False;983.113;999.4737;Comment;14;265;136;135;134;167;165;162;104;106;163;105;306;307;451;Base Texture Samples;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;159;-4401.968,291.3344;Inherit;False;2036.89;887.5413;;13;152;151;112;130;144;145;153;158;155;141;156;169;305;Height Displacement;1,0.4621924,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;33;-3654.908,1474.989;Inherit;False;867.5936;526.5638;;5;37;36;68;69;70;Mask Wind by UV2;1,0.5394964,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;320;-2601.406,-7285.537;Inherit;False;1066.546;2042.527;Comment;25;287;318;288;317;286;284;316;315;314;285;304;303;299;300;302;301;297;298;295;296;322;323;324;325;326;Top/Bottom Blends;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;258;-4674.844,-3338.381;Inherit;False;1457.155;1212.136;Comment;11;195;309;308;205;178;385;386;376;375;472;475;Snow Texture Samples;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;260;-1494.774,-1952.608;Inherit;False;878.523;1119.711;Comment;15;208;212;209;213;210;211;200;207;197;206;199;204;203;194;193;Snow Mask Blends;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;321;-4691.974,-4452.524;Inherit;False;1150.525;890.459;Comment;13;262;275;263;269;274;273;272;313;312;261;310;268;311;Bottom Textures;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;256;-4533.839,-1741.936;Inherit;False;2135.386;650.1171;;18;188;190;189;191;192;181;179;180;182;184;183;185;187;186;449;450;454;465;Snow Mask;0,0.7479331,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;319;-2647.067,-4844.135;Inherit;False;1044.454;498.1787;Comment;6;277;280;292;282;283;453;Bottom Texture Mask;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;106;-4643.965,-5217.769;Inherit;True;Property;_Mask;Smoothness (R), Ambient Occlusion (G), Height (A);2;0;Create;False;0;0;0;False;0;False;-1;None;29bcd0a346a3a0344ac6aa5d1f4bdd46;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;134;-4300.4,-4937.455;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;265;-3933.009,-4941.63;Inherit;False;HeightMap;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;277;-2597.067,-4794.135;Inherit;False;265;HeightMap;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;453;-2555.823,-4503.616;Inherit;False;Property;_BlendStrength;Blend Strength;23;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;283;-1858.614,-4715.041;Inherit;False;TopBottomMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;105;-4647.917,-5421.534;Inherit;True;Property;_Normal;Normal;1;0;Create;True;0;0;0;False;0;False;-1;None;4d42af96c852f474fa8263fd309f1532;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.HeightMapBlendNode;282;-2142.021,-4710.468;Inherit;False;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;262;-4641.974,-4185.02;Inherit;True;Property;_BottomNormal;Bottom Normal;7;0;Create;True;0;0;0;False;0;False;-1;None;28b8bed06a9a18444b9bc77dbb9dbdf5;True;2;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;135;-4619.931,-4822.548;Inherit;False;Property;_HeightMin;Height Min;4;0;Create;True;0;0;0;True;0;False;0;-0.02;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;280;-2335.894,-4547.957;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;292;-2374.13,-4789.736;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;20;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;136;-4618.172,-4749.256;Inherit;False;Property;_HeightMax;Height Max;5;0;Create;True;0;0;0;True;0;False;0;0.12;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;296;-2534.173,-6779.028;Inherit;False;269;BottomNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;269;-4276.634,-4184.219;Inherit;False;BottomNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;263;-4638.942,-3972.167;Inherit;True;Property;_BottomMask;Bottom Smoothness (R), Ambient Occlusion (G), Height (A);8;0;Create;False;0;0;0;True;0;False;-1;None;b0e1c15906bb905438c40cff7fceaf6c;True;2;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;181;-4517.117,-1499.589;Inherit;False;Property;_SnowAmount;Snow Amount;18;0;Create;True;0;0;0;False;0;False;0;2;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;450;-4212.516,-1460.894;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;274;-4587.603,-3752.958;Inherit;False;Property;_BottomHeightMin;Bottom Height Min;10;0;Create;True;0;0;0;True;0;False;0;-0.2;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;275;-4585.843,-3677.065;Inherit;False;Property;_BottomHeightMax;Bottom Height Max;11;0;Create;True;0;0;0;True;0;False;1;0.23;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;295;-2517.118,-6875.843;Inherit;False;163;NormalMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;179;-4518.126,-1678.81;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;298;-2538.594,-6658.205;Inherit;False;283;TopBottomMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;163;-4264.913,-5420.882;Inherit;False;NormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;449;-4517.219,-1410.976;Inherit;False;Global;TFW_SnowAmount;TFW_SnowAmount;22;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;77;-4205.747,2061.609;Float;False;Property;_WindSpeed;Wind Speed;14;0;Create;True;0;0;0;False;0;False;1;1;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-4121.868,2156.319;Inherit;False;Property;_WindNoiseScale;Wind Noise Scale;13;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;301;-2516.106,-6039.221;Inherit;False;272;BottomHeight;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;187;-3671.722,-1559.174;Inherit;True;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;104;-4649.39,-5614.448;Inherit;True;Property;_MainTex;Albedo;0;0;Create;False;0;0;0;False;0;False;-1;None;a2732e0630ee9f84c9c21c70be674f2c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;141;-4107.697,974.8782;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;156;-4126.456,835.1597;Inherit;False;Property;_TessellationSeamMask;Tessellation Seam Mask;22;0;Create;True;0;0;0;True;0;False;3;1.85;0.1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;303;-2188.998,-6121.735;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;185;-3895.841,-1301.234;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;180;-4102.611,-1641.793;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;182;-3918.61,-1641.793;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;302;-2499.051,-6136.036;Inherit;False;265;HeightMap;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;184;-4152.841,-1227.234;Inherit;False;178;SnowNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;183;-4200.84,-1321.234;Inherit;False;299;NormalBottomBlend;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;300;-2520.527,-5918.398;Inherit;False;283;TopBottomMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;272;-3816.309,-3886.8;Inherit;False;BottomHeight;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;304;-1942.929,-6127.629;Inherit;True;HeightBottomBlend;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;261;-4641.338,-4401.122;Inherit;True;Property;_BottomAlbedo;Bottom Albedo;6;0;Create;True;0;0;0;False;0;False;-1;None;56b6155ed83dbb34a961e310e7711cd3;True;2;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;155;-3829.455,850.1597;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;287;-2520.243,-7043.664;Inherit;False;283;TopBottomMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;153;-3643.578,701.6829;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;273;-4263.514,-3875.849;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;145;-3631.008,872.0103;Inherit;False;Property;_DisplacementStrength;Displacement Strength;20;0;Create;True;0;0;0;False;0;False;1;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;178;-3445.567,-2760.613;Inherit;False;SnowNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;162;-4276.913,-5612.882;Inherit;False;Albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;299;-1960.996,-6867.437;Inherit;False;NormalBottomBlend;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;305;-4121.277,580.5101;Inherit;False;304;HeightBottomBlend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;268;-4273.109,-4402.524;Inherit;False;BottomAlbedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;158;-4120.455,713.1596;Inherit;False;Property;_TessellationSeamOffset;Tessellation Seam Offset;21;0;Create;True;0;0;0;False;0;False;0;0.02;-3;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;36;-3632.388,1525.158;Inherit;True;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;69;-3399.679,1687.678;Inherit;False;Constant;_Float7;Float 7;3;0;Create;True;0;0;0;False;0;False;2.34;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;285;-2508.733,-7146.763;Inherit;False;268;BottomAlbedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;297;-2207.065,-6861.543;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;284;-2473.937,-7235.537;Inherit;False;162;Albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;214;-325.4685,224.4323;Inherit;False;213;FinalAmbientOcclusion;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;201;-253.9667,-77.26117;Inherit;False;200;FinalAlbedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;286;-2226.462,-7231.241;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;68;-3361.012,1543.512;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;38;-3057.554,2095.98;Inherit;False;Property;_WindStrength;Wind Strength;12;0;Create;True;0;0;0;False;0;False;0.3;0.3;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;-3370.527,656.9854;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;288;-2010.262,-7235.536;Inherit;False;AlbedoBottomBlend;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;151;-3040.294,1022.247;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;195;-3487.442,-3269.366;Inherit;False;SnowAlbedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;192;-2654.454,-1356.82;Inherit;False;SnowBlendMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;202;-261.9667,9.738831;Inherit;False;186;NormalBlend;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;-3088.007,730.5522;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;152;-2831.663,861.0515;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;194;-1412.027,-1805.637;Inherit;False;195;SnowAlbedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;39;-2731.943,1967.561;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;70;-3197.913,1546.781;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;310;-3820.449,-4052.005;Inherit;False;BottomSmoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;216;-291.5009,112.0848;Inherit;False;208;FinalSmoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;200;-955.9055,-1857.405;Inherit;False;FinalAlbedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;170;-272.5112,522.7437;Inherit;False;169;HeightDisplacement;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;171;-223.6785,670.0059;Inherit;False;168;MainWind;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;207;-1146.851,-1477.796;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;168;-2574.729,1963.499;Inherit;False;MainWind;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;130;-3348.731,859.6037;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;169;-2644.369,855.6236;Inherit;False;HeightDisplacement;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;193;-1451.348,-1901.608;Inherit;False;288;AlbedoBottomBlend;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;199;-1436.839,-1712.244;Inherit;False;192;SnowBlendMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;448;-3484.685,2053.23;Inherit;False;TriforgeTreeWind;-1;;1;02c5e277b3e957a46ade320788361410;0;2;10;FLOAT;1;False;7;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;197;-1152.839,-1854.244;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;306;-4177.971,-5268.039;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-3009.371,1536.685;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;249;36.106,581.6729;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;186;-3680.841,-1230.41;Inherit;False;NormalBlend;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;313;-4311.223,-4008.284;Inherit;False;Property;_BottomSmoothness;Bottom Smoothness;9;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;451;-4000.682,-4802.93;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;205;-3497.819,-3101.214;Inherit;False;SnowSmoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;204;-1426.573,-1434.937;Inherit;False;205;SnowSmoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;311;-3817.169,-3968.934;Inherit;False;BottomAO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;208;-952.2515,-1481.096;Inherit;False;FinalSmoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;167;-3962.573,-5271.552;Inherit;False;Smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;206;-1418.351,-1341.397;Inherit;False;192;SnowBlendMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;203;-1466.074,-1530.337;Inherit;False;318;SmoothnessBottomBlend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;210;-1423.826,-1120.849;Inherit;False;326;AOBlend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;212;-1424.5,-944.6971;Inherit;False;192;SnowBlendMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;322;-2521.07,-5627.448;Inherit;False;311;BottomAO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;309;-3732.496,-2973.099;Inherit;False;Property;_SnowSmoothness;Snow Smoothness;15;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;213;-960.5005,-1072.697;Inherit;False;FinalAmbientOcclusion;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;211;-1344.5,-1032.697;Inherit;False;Constant;_Float0;Float 0;21;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;318;-1953.227,-6488.578;Inherit;False;SmoothnessBottomBlend;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;315;-2509.349,-6496.983;Inherit;False;167;Smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;326;-1947.892,-5715.856;Inherit;False;AOBlend;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;316;-2529.635,-6304.346;Inherit;False;283;TopBottomMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;325;-2193.961,-5709.962;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;323;-2504.015,-5723.263;Inherit;False;165;AmbientOcclusion;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;165;-3958.411,-5050.993;Inherit;False;AmbientOcclusion;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;312;-4025.94,-4047.633;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;317;-2199.297,-6482.684;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;308;-3669.248,-3097.901;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;324;-2525.491,-5506.625;Inherit;False;283;TopBottomMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;314;-2551.406,-6402.549;Inherit;False;310;BottomSmoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;209;-1156.251,-1065.896;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;307;-4177.971,-5158.039;Inherit;False;Property;_Smoothness;Smoothness;3;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;462;445.6431,119.7814;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;GBuffer;0;7;GBuffer;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalGBuffer;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;458;445.6431,59.78136;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;461;445.6431,119.7814;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthNormals;0;6;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormals;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;459;445.6431,59.78136;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;456;445.6431,59.78136;Float;False;True;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;TriForge/Winter Forest/Bark Double - Tessellation;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;21;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;2;Include;;False;;Native;False;0;0;;Include;Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl;False;;Custom;False;0;0;;Hidden/InternalErrorShader;0;0;Standard;40;Workflow;1;0;Surface;0;0;  Refraction Model;0;0;  Blend;0;0;Two Sided;1;0;Fragment Normal Space,InvertActionOnDeselection;0;0;Forward Only;0;0;Transmission;0;0;  Transmission Shadow;0.5,False,;0;Translucency;0;0;  Translucency Strength;1,False,;0;  Normal Distortion;0.5,False,;0;  Scattering;2,False,;0;  Direct;0.9,False,;0;  Ambient;0.1,False,;0;  Shadow;0.5,False,;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;GPU Instancing;0;0;LOD CrossFade;1;0;Built-in Fog;1;0;_FinalColorxAlpha;0;0;Meta Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;0;DOTS Instancing;0;0;Tessellation;1;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;1;0;  Tess;12,False,;0;  Min;4,False,;0;  Max;12,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Write Depth;0;0;  Early Z;0;0;Vertex Position,InvertActionOnDeselection;1;0;Debug Display;0;0;Clear Coat;0;0;0;10;False;True;True;True;True;True;True;True;True;True;False;;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;460;445.6431,59.78136;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;457;445.6431,59.78136;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;463;445.6431,139.7814;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;SceneSelectionPass;0;8;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;455;445.6431,59.78136;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;464;445.6431,139.7814;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ScenePickingPass;0;9;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.CommentaryNode;270;-1445.201,-2926.171;Inherit;False;100;100;Comment;0;Vertex Color Blue - Tessellation Seam Mask;0,0.1061859,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;403;-1442.115,-3883.834;Inherit;False;100;100;Comment;0;Legend:;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;267;-1436.273,-3608.345;Inherit;False;106.2295;100;Comment;0;UV2 - Wind Mask, UV3 - Tree Bottom Textures;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;271;-1444.276,-3138.58;Inherit;False;100;100;Comment;0;Vertex Color Green - Tessellation Mask;0.2058077,1,0.1462264,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;276;-1440.946,-3330.367;Inherit;False;100;100;Comment;0;Vertex Color Red - Blend mask for Bottom Textures;0.9339623,0,0,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;188;-3250.299,-1457.384;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;190;-3369.297,-1217.78;Inherit;False;Property;_SnowMaskSharpness;Snow Mask Sharpness;19;0;Create;True;0;0;0;False;0;False;1;1.72;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;191;-2841.356,-1360.246;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;465;-3433.617,-1558.263;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;386;-3865.969,-2760.936;Inherit;True;Property;_TextureSample1;Texture Sample 1;30;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;376;-4311.534,-2752.914;Inherit;True;Property;_SnowNormal;Snow Normal;17;0;Create;False;0;0;0;False;0;False;None;None;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;385;-4035.638,-3267.289;Inherit;True;Property;_TextureSample0;Texture Sample 0;30;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;375;-4324.901,-3269.326;Inherit;True;Property;_SnowAlbedo;Snow Albedo;16;0;Create;False;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.PowerNode;189;-3062.592,-1359.3;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;454;-4308.724,-1640.081;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerStateNode;466;-5580.952,-5888.206;Inherit;False;0;0;0;2;-1;X16;1;0;SAMPLER2D;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.SamplerStateNode;467;-5581.881,-5782.608;Inherit;False;0;0;0;2;-1;X16;1;0;SAMPLER2D;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;468;-5342.881,-5889.608;Inherit;False;SS;-1;True;1;0;SAMPLERSTATE;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;469;-5336.881,-5783.608;Inherit;False;SS_Normal;-1;True;1;0;SAMPLERSTATE;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.GetLocalVarNode;471;-5030.002,-4355.884;Inherit;False;468;SS;1;0;OBJECT;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.GetLocalVarNode;472;-4305.582,-3028.202;Inherit;False;468;SS;1;0;OBJECT;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.GetLocalVarNode;470;-4967.388,-5567.798;Inherit;False;468;SS;1;0;OBJECT;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.GetLocalVarNode;473;-4971.977,-5386.768;Inherit;False;469;SS_Normal;1;0;OBJECT;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.GetLocalVarNode;474;-5018.717,-4163.727;Inherit;False;469;SS_Normal;1;0;OBJECT;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.GetLocalVarNode;475;-4272.73,-2524.203;Inherit;False;469;SS_Normal;1;0;OBJECT;;False;1;SAMPLERSTATE;0
WireConnection;106;7;470;0
WireConnection;134;0;106;4
WireConnection;134;3;135;0
WireConnection;134;4;136;0
WireConnection;265;0;134;0
WireConnection;283;0;282;0
WireConnection;105;7;473;0
WireConnection;282;0;292;0
WireConnection;282;1;280;1
WireConnection;282;2;453;0
WireConnection;262;7;474;0
WireConnection;292;0;277;0
WireConnection;269;0;262;0
WireConnection;263;7;471;0
WireConnection;450;0;181;0
WireConnection;450;1;449;0
WireConnection;163;0;105;0
WireConnection;187;0;185;0
WireConnection;104;7;470;0
WireConnection;303;0;302;0
WireConnection;303;1;301;0
WireConnection;303;2;300;0
WireConnection;185;0;183;0
WireConnection;185;1;184;0
WireConnection;185;2;182;0
WireConnection;180;0;454;0
WireConnection;180;1;450;0
WireConnection;182;0;180;0
WireConnection;272;0;273;0
WireConnection;304;0;303;0
WireConnection;261;7;471;0
WireConnection;155;0;141;3
WireConnection;155;1;156;0
WireConnection;153;0;305;0
WireConnection;153;1;158;0
WireConnection;153;2;155;0
WireConnection;273;0;263;4
WireConnection;273;3;274;0
WireConnection;273;4;275;0
WireConnection;178;0;386;0
WireConnection;162;0;104;0
WireConnection;299;0;297;0
WireConnection;268;0;261;0
WireConnection;297;0;295;0
WireConnection;297;1;296;0
WireConnection;297;2;298;0
WireConnection;286;0;284;0
WireConnection;286;1;285;0
WireConnection;286;2;287;0
WireConnection;68;0;36;2
WireConnection;68;1;69;0
WireConnection;144;0;153;0
WireConnection;144;1;145;0
WireConnection;288;0;286;0
WireConnection;151;0;141;2
WireConnection;195;0;385;0
WireConnection;192;0;191;0
WireConnection;112;0;144;0
WireConnection;112;1;130;0
WireConnection;152;0;112;0
WireConnection;152;1;151;0
WireConnection;39;0;37;0
WireConnection;39;1;38;0
WireConnection;70;0;68;0
WireConnection;310;0;312;0
WireConnection;200;0;197;0
WireConnection;207;0;203;0
WireConnection;207;1;204;0
WireConnection;207;2;206;0
WireConnection;168;0;39;0
WireConnection;169;0;152;0
WireConnection;448;10;77;0
WireConnection;448;7;6;0
WireConnection;197;0;193;0
WireConnection;197;1;194;0
WireConnection;197;2;199;0
WireConnection;306;0;106;1
WireConnection;306;1;307;0
WireConnection;37;0;70;0
WireConnection;37;1;448;0
WireConnection;249;0;170;0
WireConnection;249;1;171;0
WireConnection;186;0;185;0
WireConnection;451;0;134;0
WireConnection;205;0;308;0
WireConnection;311;0;263;2
WireConnection;208;0;207;0
WireConnection;167;0;306;0
WireConnection;213;0;209;0
WireConnection;318;0;317;0
WireConnection;326;0;325;0
WireConnection;325;0;323;0
WireConnection;325;1;322;0
WireConnection;325;2;324;0
WireConnection;165;0;106;2
WireConnection;312;0;263;1
WireConnection;312;1;313;0
WireConnection;317;0;315;0
WireConnection;317;1;314;0
WireConnection;317;2;316;0
WireConnection;308;0;385;4
WireConnection;308;1;309;0
WireConnection;209;0;210;0
WireConnection;209;1;211;0
WireConnection;209;2;212;0
WireConnection;456;0;201;0
WireConnection;456;1;202;0
WireConnection;456;4;216;0
WireConnection;456;5;214;0
WireConnection;456;8;249;0
WireConnection;188;0;465;0
WireConnection;188;1;450;0
WireConnection;191;0;189;0
WireConnection;465;0;187;2
WireConnection;386;0;376;0
WireConnection;386;7;475;0
WireConnection;385;0;375;0
WireConnection;385;7;472;0
WireConnection;189;0;188;0
WireConnection;189;1;190;0
WireConnection;454;0;179;2
WireConnection;468;0;466;0
WireConnection;469;0;467;0
ASEEND*/
//CHKSM=3EB2D7A0C6688698A1955060FD6F9EFF54295E4C