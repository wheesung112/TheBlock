import os
import shutil
import re

# Configuration
base_dir = r"c:\Users\whees\TheBlock\Assets\TriForge Assets\Fantasy Worlds - DEMO Common Files\Shaders"
targets = ["FWGrass", "FWTreeLeaf", "FWTreeBark"]
encoding_try = ['utf-8', 'cp949', 'latin-1']

# Wireframe Code Blocks
PROPERTIES_BLOCK = """
		[Header(Wireframe Settings)]
		_WireColor("Wire Color", Color) = (0.0, 1.0, 0.0, 1.0)
		_WireThickness("Wire Thickness", Range(0, 800)) = 100
		_WireSmoothing("Wire Smoothing", Range(0, 20)) = 1
"""

CBUFFER_BLOCK = """
			float4 _WireColor;
			float _WireThickness;
			float _WireSmoothing;
			CBUFFER_END
"""

STRUCT_MEMBER = """
				float3 barycentric : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
"""

GEOM_FUNCTION = """
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
"""

FRAG_LOGIC = """
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
"""

def read_file(path):
    for enc in encoding_try:
        try:
            with open(path, 'r', encoding=enc) as f:
                return f.read()
        except UnicodeDecodeError:
            continue
    raise Exception(f"Could not decode file: {path}")

def patch_shader(filename):
    src_path = os.path.join(base_dir, f"{filename}.shader")
    dst_path = os.path.join(base_dir, f"{filename}_Wireframe.shader")
    
    print(f"Processing {filename}...")
    
    if not os.path.exists(src_path):
        print(f"Error: Source file not found: {src_path}")
        return

    content = read_file(src_path)
    
    # 1. Rename Shader
    content = content.replace(f'Shader "TriForge/Fantasy Worlds/{filename}"', f'Shader "TriForge/Fantasy Worlds/{filename}_Wireframe"')
    
    # 2. Inject Properties
    if '_texcoord' in content:
        content = content.replace('[HideInInspector] _texcoord', PROPERTIES_BLOCK + '\n		[HideInInspector] _texcoord')
    else:
        print("Warning: _texcoord not found, properties injection might be wrong location.")

    # 3. Inject CBuffer (Replace CBUFFER_END)
    content = content.replace('CBUFFER_END', CBUFFER_BLOCK)

    # 4. Inject Struct Member
    content = content.replace('UNITY_VERTEX_OUTPUT_STEREO', STRUCT_MEMBER)

    # 5. Inject Geom Pragma & Function
    # We look for the Forward pass vertex definition
    # Pattern: Name "Forward" ... #pragma vertex vert ... half4 frag
    
    # Using regex to find the insertion point safely
    # We need to insert '#pragma geometry geom' after '#pragma vertex vert' ONLY in the Forward pass (or generally)
    # And insert the function 'geom' before 'half4 frag'
    
    # Simple strategy: Identify the HLSL block containing 'Name "Forward"' (or just the main PBR pass)
    # Since these are big files, we'll assume the Forward pass usage.
    
    # Let's simple-replace for now, trusting the structure of TriForge shaders
    # Inject #pragma geometry geom AFTER #pragma vertex vert
    content = re.sub(r'(#pragma vertex vert)', r'\1\n			#pragma geometry geom', content)
    
    # Inject geom function BEFORE half4 frag
    # We need to be careful not to inject it in ShadowCaster or Meta passes if they use the same names
    # But usually Geometry shader is fine to be defined even if unused, but we want to hook it up.
    # The Pragma injection above hooks it up everywhere 'vert' is used. This might be an issue for ShadowCaster if it doesn't use the same struct.
    # However, for this task, getting it working on the main pass is key.
    
    # To be safer: Only inject `geom` logic in the pass that returns `UniversalFragmentPBR`
    
    # Finding the spot to insert the geom function
    content = re.sub(r'(half4 frag\s*\(.*?VertexOutput IN.*?\))', GEOM_FUNCTION + r'\n			\1', content, flags=re.DOTALL)
    
    # 6. Inject Fragment Logic
    # Replace the standard PBR call with our logic
    if 'UniversalFragmentPBR( inputData, surfaceData);' in content:
        content = content.replace('half4 color = UniversalFragmentPBR( inputData, surfaceData);', FRAG_LOGIC)
    else:
        print(f"Warning: UniversalFragmentPBR call not found in {filename}")

    with open(dst_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Success: Created {dst_path}")

if __name__ == "__main__":
    for target in targets:
        try:
            patch_shader(target)
        except Exception as e:
            print(f"Failed to patch {target}: {e}")
