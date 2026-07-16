$files = @("FWGrass", "FWTreeLeaf", "FWTreeBark")
$baseDir = "c:\Users\whees\TheBlock\Assets\TriForge Assets\Fantasy Worlds - DEMO Common Files\Shaders"

$wireProps = @"
		[Header(Wireframe Settings)]
		_WireColor("Wire Color", Color) = (0.0, 1.0, 0.0, 1.0)
		_WireThickness("Wire Thickness", Range(0, 800)) = 100
		_WireSmoothing("Wire Smoothing", Range(0, 20)) = 1
"@

$wireCBuffer = @"
			float4 _WireColor;
			float _WireThickness;
			float _WireSmoothing;
			CBUFFER_END
"@

$wireStruct = @"
				float3 barycentric : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
"@

$geomFunc = @"
			[maxvertexcount(3)]
			void geom(triangle VertexOutput IN[3], inout TriangleStream<VertexOutput> triStream)
			{
				float2 p0 = IN[0].clipPos.xy / IN[0].clipPos.w;
				float2 p1 = IN[1].clipPos.xy / IN[1].clipPos.w;
				float2 p2 = IN[2].clipPos.xy / IN[2].clipPos.w;

				float2 edge0 = p2 - p1;
				float2 edge1 = p2 - p0;
				float2 edge2 = p1 - p0;

				float area = abs(edge1.x * edge2.y - edge1.y * edge2.x);
				float wireThickness = 800 - _WireThickness;

				VertexOutput o = IN[0];
				o.barycentric = float3(area / length(edge0), 0, 0) * o.clipPos.w * wireThickness;
				triStream.Append(o);

				o = IN[1];
				o.barycentric = float3(0, area / length(edge1), 0) * o.clipPos.w * wireThickness;
				triStream.Append(o);

				o = IN[2];
				o.barycentric = float3(0, 0, area / length(edge2)) * o.clipPos.w * wireThickness;
				triStream.Append(o);
			}
"@

$fragLogic = @"
				half4 color = UniversalFragmentPBR( inputData, surfaceData);
				
				// Wireframe Blend
				float3 barys = IN.barycentric;
				float3 deltas = fwidth(barys);
				float3 smoothing = deltas * _WireSmoothing;
				float3 thickness = deltas * _WireThickness;
				barys = smoothstep(thickness, thickness + smoothing, barys);
				float minBary = min(barys.x, min(barys.y, barys.z));
				float wireMask = 1.0 - minBary;
				if (_WireThickness > 0)
				{
					color.rgb = lerp(color.rgb, _WireColor.rgb, wireMask * _WireColor.a);
				}
"@

foreach ($name in $files) {
    $srcPath = Join-Path $baseDir "$name.shader"
    $dstPath = Join-Path $baseDir "${name}_Wireframe.shader"
    
    Write-Host "Processing $name..."
    $content = Get-Content -Path $srcPath -Raw
    
    # 1. Rename Shader
    $content = $content -replace "Shader ""TriForge/Fantasy Worlds/$name""", "Shader ""TriForge/Fantasy Worlds/${name}_Wireframe"""
    
    # 2. Inject Properties
    $content = $content -replace '\[HideInInspector\] _texcoord', ($wireProps + "`n		[HideInInspector] _texcoord")
    
    # 3. Inject CBuffer (Replace all occurrences to be safe/consistent)
    $content = $content -replace 'CBUFFER_END', $wireCBuffer
    
    # 4. Inject Struct Member
    $content = $content -replace 'UNITY_VERTEX_OUTPUT_STEREO', $wireStruct
    
    # 5. Inject Geom Pragma (Logic: Find 'Name "Forward"' then find '#pragma vertex vert' after it)
    # Using regex with Singleline mode (?s)
    $content = $content -replace '(?s)(Name "Forward".*?#pragma vertex vert)', ("`$1`n			#pragma geometry geom")
    
    # 6. Inject Geom Function (Logic: Find 'Name "Forward"' then find 'half4 frag' after it)
    $content = $content -replace '(?s)(Name "Forward".*?)(half4 frag)', ("`$1" + $geomFunc + "`n			half4 frag")
    
    # 7. Inject Fragment Logic
    $content = $content -replace 'half4 color = UniversalFragmentPBR\( inputData, surfaceData\);', $fragLogic
    
    Set-Content -Path $dstPath -Value $content
    Write-Host "Created $dstPath"
}
