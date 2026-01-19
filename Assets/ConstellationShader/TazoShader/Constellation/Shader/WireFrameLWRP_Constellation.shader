Shader "Tazo/WireframeConstellation-LWRP"
{
	Properties
	{
		[Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 0
		//[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 1
		_Bright("Over All Bright", RANGE(0,5)) = 2
		[Header(Constellation)]
		_TintColor("_TintColor", Color) = (1,1,1,1)
		[NoScaleOffset]_MainTex("Constellation Map and Mask", 2D) = "black" {}
		_UVLOOP("UV Loop", RANGE(0, 50)) = 1
		[Header(Wire)]
		_WireThickness("Wire Thickness", RANGE(0, 800)) = 100
		_WireSmoothness("Wire Smoothness", RANGE(0, 20)) = 3
		[HDR]_WireColor("Wire Color", Color) = (0.0, 1.0, 0.0, 1.0)
		_BaseColor("Base Color", Color) = (0.0, 0.0, 0.0, 1.0)
			
		[Header(Fresnel)]
		_FresnelAmount("Fresnel Amount", Range(-1, 50)) = 1
		_FresnelThreshold("_Fresnel Threshold",  Range(0, 10)) = 0.07
		

		[Header(Distortion)]
		[NoScaleOffset]_Mask("Distortion Map", 2D) = "white" {}
		_UVMLOOP("UV Loop", RANGE(0, 50)) = 1
		_UVDisMap("Wire Distortion_Scale",Range(-1, 1)) = 0.0
		_DisMapScrollX("Wire U Speed",Float) = 0.0
		_DisMapScrollY("Wire V Speed",FLoat) = 0.0
		_UVDisMap1("Solid Distortion_Scale",Range(-1, 1)) = 0.0
		_DisMapScrollX1("Solid U Speed",Float) = 0.0
		_DisMapScrollY1("Solid V Speed",FLoat) = 0.0

		[Header(Hoop)]
		
		_Thickness("Hoop Strength", Range(0,10)) = 0.025
		_HoopTex("HoopMask", 2D) = "white" {}
		_Speed("Hoop Speed", Range(0,5)) = 1



			[Header(Rim)]
		 //_MainTex("Mask", 2D) = "white" {}
		_Color("Color", Color) = (1, 1, 1, 1)
		_RimEffect("Rim effect", Range(0, 1)) = 0
		_pow("POW", Range(0, 10)) = 2
	}

		SubShader
		{
			Tags {
				"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		
			}

		
	

		Pass
		{
			ZWrite[_ZWrite]
			//ZTest[_ZTest]
			Cull[_Cull]
			//ZWrite On
			//Cull Back
			Tags {"LightMode" = "LightweightForward"}
			
	
			Blend OneMinusDstColor One
			//Blend SrcAlpha OneMinusSrcAlpha
			//Cull Back
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"
			float _UVDisMap;
		float _DisMapScrollX;
		float _DisMapScrollY;
		float _UVDisMap1;
		float _DisMapScrollX1;
		float _DisMapScrollY1;
			uniform sampler2D _Mask; uniform float4 _Mask_ST;
			uniform float _WireThickness;
			uniform float _WireSmoothness;
			uniform float4 _WireColor;
			uniform float4 _BaseColor;

			float _FresnelAmount;
			float _FresnelThreshold;
			sampler2D _HoopTex;
			float4  _HoopTex_ST;
			float _Thickness;
			float _Speed;
			float _pow;

			sampler2D   _MainTex;
			float4      _MainTex_ST;
			float _UVLOOP;
			float _UVMLOOP;
			float4  _TintColor;
			float _Bright;
			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
				float3 normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2g
			{
				float4 projectionSpaceVertex : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				
				float4 worldSpacePosition : TEXCOORD1;

				float3 rim : TEXCOORD2;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct g2f
			{
				float4 projectionSpaceVertex : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				
				float4 worldSpacePosition : TEXCOORD1;
				float4 dist : TEXCOORD2;
				float3 rim : TEXCOORD3;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2g vert(appdata v)
			{
				v2g o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.projectionSpaceVertex = UnityObjectToClipPos(v.vertex);
				o.worldSpacePosition = mul(unity_ObjectToWorld, v.vertex);
				o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
				/////////////////////////////////////////////////////////////////////////////////////
				float2 texcoord_3d = TRANSFORM_TEX(v.vertex.yx, _HoopTex);
				float hoop = 0.5 + tex2Dlod(_HoopTex, float4(texcoord_3d.x, texcoord_3d.y + _Time.y * _Speed, 0, 0)).r * _Thickness;

				float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
				float dotProduct = 1 - abs(dot(v.normal, viewDir)) * _FresnelAmount;
				o.rim =  pow(dotProduct,_FresnelThreshold)  /*hoop*/;
				///////////////////////////////////////
				return o;
			}

			[maxvertexcount(3)]
			void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
			{
				float2 p0 = i[0].projectionSpaceVertex.xy / i[0].projectionSpaceVertex.w;
				float2 p1 = i[1].projectionSpaceVertex.xy / i[1].projectionSpaceVertex.w;
				float2 p2 = i[2].projectionSpaceVertex.xy / i[2].projectionSpaceVertex.w;

				float2 edge0 = p2 - p1;
				float2 edge1 = p2 - p0;
				float2 edge2 = p1 - p0;

				// To find the distance to the opposite edge, we take the
				// formula for finding the area of a triangle Area = Base/2 * Height, 
				// and solve for the Height = (Area * 2)/Base.
				// We can get the area of a triangle by taking its cross product
				// divided by 2.  However we can avoid dividing our area/base by 2
				// since our cross product will already be double our area.
				float area = abs(edge1.x * edge2.y - edge1.y * edge2.x);
				float wireThickness = 800 - _WireThickness;

				g2f o;

				o.uv0 = i[0].uv0;
				o.rim = i[0].rim;

				o.worldSpacePosition = i[0].worldSpacePosition;
				o.projectionSpaceVertex = i[0].projectionSpaceVertex;
				o.dist.xyz = float3((area / length(edge0)), 0.0, 0.0) * o.projectionSpaceVertex.w * wireThickness;
				o.dist.w = 1.0 / o.projectionSpaceVertex.w;
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o);
				triangleStream.Append(o);

				o.uv0 = i[1].uv0;
				o.rim = i[1].rim;
				o.worldSpacePosition = i[1].worldSpacePosition;
				o.projectionSpaceVertex = i[1].projectionSpaceVertex;
				o.dist.xyz = float3(0.0, (area / length(edge1)), 0.0) * o.projectionSpaceVertex.w * wireThickness;
				o.dist.w = 1.0 / o.projectionSpaceVertex.w;
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[1], o);
				triangleStream.Append(o);

				o.uv0 = i[2].uv0;
				o.rim = i[2].rim;
				o.worldSpacePosition = i[2].worldSpacePosition;
				o.projectionSpaceVertex = i[2].projectionSpaceVertex;
				o.dist.xyz = float3(0.0, 0.0, (area / length(edge2))) * o.projectionSpaceVertex.w * wireThickness;
				o.dist.w = 1.0 / o.projectionSpaceVertex.w;
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[2], o);
				triangleStream.Append(o);
			}

			float4 frag(g2f i) : SV_Target
			{

				float3 move = 0;
				move = float3(_DisMapScrollX, _DisMapScrollY,0.0) * _Time.y;
				half3 fdDis = tex2D(_Mask, i.uv0 * _UVMLOOP + move.xy).rgb;
				float4 mt = tex2D(_Mask, i.uv0 * _UVMLOOP + fdDis.xy * _UVDisMap);
				float3 move1 = 0;
				move1 = float3(_DisMapScrollX1, _DisMapScrollY1, 0.0) * _Time.y;
				half3 fdDis1 = tex2D(_Mask, i.uv0 * _UVMLOOP + move1.xy).rgb;
				float4 mt1 = tex2D(_Mask, i.uv0 *_UVMLOOP + fdDis1.xy * _UVDisMap1);

				float minDistanceToEdge = min(i.dist[0], min(i.dist[1], i.dist[2])) * i.dist[3];
				float fade_out = tex2D(_MainTex, i.uv0).a;
				
				float4 con = tex2D(_MainTex, i.uv0* _UVLOOP).r*_TintColor ;
				float4 baseColor = (_BaseColor+ con* _TintColor.a)* fade_out;

				// Early out if we know we are not on a line segment.
				if (minDistanceToEdge > 0.9)
				{
					return float4(baseColor.rgb,0);
				}

				// Smooth our line out
				
				
				float t = exp2(_WireSmoothness * -1.0 * minDistanceToEdge * minDistanceToEdge);
				float4 finalColor = lerp(baseColor*mt1 * _Bright, _WireColor * fade_out * mt* _Bright, t);
				finalColor.rgb *= saturate(i.rim);
				finalColor.a = t * saturate(i.rim);

				return finalColor ;
			}
			ENDCG
		}
		Pass{
			Tags{ "LightMode" = "SRPDefaultUnlit" }
				//Tags {"LightMode" = "UniversalForward"}
			Blend One One
			Cull Back
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f {
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
				float3 rim : TEXCOORD2;
			};
		
		sampler2D _HoopTex;
		float4  _HoopTex_ST;
		float _Thickness;
		float _Speed;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _pow;
			float _RimEffect;
			v2f vert(appdata_full v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal.xyz));
				o.viewDir = normalize(_WorldSpaceCameraPos - mul((float3x3)unity_ObjectToWorld, v.vertex.xyz));
				o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);


				float2 texcoord_3d = TRANSFORM_TEX(v.vertex.yx, _HoopTex);
				float hoop =0.5 + tex2Dlod(_HoopTex, float4(texcoord_3d.x, texcoord_3d.y + _Time.y * _Speed, 0, 0)).r * _Thickness;


				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3  myviewDir = WorldSpaceViewDir(v.vertex);
				//float3 myviewDir = normalize(ObjSpaceViewDir(v.vertex));
				//float dotProduct = 1 - abs(dot(v.normal, myviewDir)) * _RimEffect;
				float dotProduct = 1 - abs(dot(worldNormal, myviewDir)) * _RimEffect;
				o.rim = pow(dotProduct, _pow) * hoop;
				o.rim.b = hoop;
				return o;
			}

			float4 _Color;
			

			float4 frag(v2f i) : COLOR {
				float t = tex2D(_MainTex, i.uv).a;
				float val = 1 - abs(dot(i.viewDir, i.normal)) * _RimEffect;
				val = pow(val,_pow);
				_Color.a = t;
				return _Color * _Color.a * val * i.rim.b;
				//return _Color * _Color.a *i.rim.r;
			}

			ENDCG
		}
		



		}
}