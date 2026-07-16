import os
import re

prop_block = """
\t\t_WireColor("Wire Color", Color) = (0.0, 1.0, 0.0, 1.0)
\t\t_WireThickness("Wire Thickness", Range(0, 800)) = 100
\t\t_WireSmoothing("Wire Smoothing", Range(0, 10)) = 1
"""

cbuffer_block = """
\t\t\tfloat4 _WireColor;
\t\t\tfloat _WireThickness;
\t\t\tfloat _WireSmoothing;
"""

geom_func = """
\t\t\t[maxvertexcount(3)]
\t\t\tvoid geom(triangle VertexOutput IN[3], inout TriangleStream<VertexOutput> triStream)
\t\t\t{
\t\t\t\tfloat2 p0 = IN[0].clipPos.xy / IN[0].clipPos.w;
\t\t\t\tfloat2 p1 = IN[1].clipPos.xy / IN[1].clipPos.w;
\t\t\t\tfloat2 p2 = IN[2].clipPos.xy / IN[2].clipPos.w;

\t\t\t\tfloat2 edge0 = p2 - p1;
\t\t\t\tfloat2 edge1 = p2 - p0;
\t\t\t\tfloat2 edge2 = p1 - p0;

\t\t\t\tfloat area = abs(edge1.x * edge2.y - edge1.y * edge2.x);
\t\t\t\tfloat wireThickness = 800 - _WireThickness;

\t\t\t\tVertexOutput o = IN[0];
\t\t\t\to.barycentric = float3(area / length(edge0), 0, 0) * o.clipPos.w * wireThickness;
\t\t\t\ttriStream.Append(o);

\t\t\t\to = IN[1];
\t\t\t\to.barycentric = float3(0, area / length(edge1), 0) * o.clipPos.w * wireThickness;
\t\t\t\ttriStream.Append(o);

\t\t\t\to = IN[2];
\t\t\t\to.barycentric = float3(0, 0, area / length(edge2)) * o.clipPos.w * wireThickness;
\t\t\t\ttriStream.Append(o);
\t\t\t}
"""

mix_logic = """
\t\t\t\tfloat3 barys = IN.barycentric;
\t\t\t\t// float3 deltas = fwidth(barys); // deltas handled in geom
\t\t\t\t// float3 smoothing = deltas * _WireSmoothing;
\t\t\t\t// float3 thickness = deltas * _WireThickness; // already in barys
\t\t\t\t// barys = smoothstep(thickness, thickness + smoothing, barys);
\t\t\t\t
\t\t\t\t// Simple mix based on min barycentric
\t\t\t\tfloat minBary = min(barys.x, min(barys.y, barys.z));
\t\t\t\tminBary /= IN.clipPos.w;
\t\t\t\tfloat edgeIntensity = smoothstep(0, _WireSmoothing, minBary);
"""

def patch_shader(filename, texcoord_idx):
    print(f"Patching {filename}...")
    try:
        with open(filename, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return

    # Update Name
    content = re.sub(r'Shader "([^"]+)"', r'Shader "\1_Wireframe"', content, count=1)
    
    # Add Properties
    # Insert after Properties {
    content = re.sub(r'Properties\s*\{', 'Properties\n\t{' + prop_block, content, count=1)
    
    # Split by HLSLPROGRAM to iterate passes
    # We use a placeholder to join later
    parts = content.split('HLSLPROGRAM')
    new_parts = [parts[0]]
    
    patched_forward = False

    for i in range(1, len(parts)):
        chunk = parts[i]
        
        # Identify Forward Pass
        # Look for SHADERPASS_FORWARD or SHADERPASS_FORWARD transition or just 'Name "Forward"' in previous block
        # We also check for 'pragma vertex vert' to ensure it's a vertex/frag shader block
        
        is_forward = False
        if '#define SHADERPASS SHADERPASS_FORWARD' in chunk:
            is_forward = True
        elif 'Name "Forward"' in parts[i-1] and '#pragma vertex vert' in chunk:
            is_forward = True
            
        if is_forward and not patched_forward:
            print(f"  Found Forward Pass in chunk {i}")
            
            # 1. Add Geometry Pragma
            if '#pragma geometry geom' not in chunk:
                chunk = chunk.replace('#pragma vertex vert', '#pragma vertex vert\n\t\t\t#pragma geometry geom')
            
            # 2. Add CBUFFER props
            if 'float4 _WireColor;' not in chunk:
                chunk = chunk.replace('CBUFFER_START(UnityPerMaterial)', 'CBUFFER_START(UnityPerMaterial)\n' + cbuffer_block)
            
            # 3. Add VertexOutput member
            # Regex for struct VertexOutput { ... };
            # We insert before the closing };
            # We capture the whole struct body to avoid matching other structs
            
            # The regex finds "struct VertexOutput", then "{" then any chars until "};"
            # Note: DOTALL is mostly needed but we can iterate lines or use re.S
            
            struct_pattern = re.compile(r'(struct VertexOutput\s*\{.*?\};)', re.DOTALL)
            match = struct_pattern.search(chunk)
            if match:
                original_struct = match.group(1)
                if 'barycentric' not in original_struct:
                    # Insert before };
                    updated_struct = original_struct.replace('};', f'\tfloat3 barycentric : TEXCOORD{texcoord_idx};\n\t\t\t}};')
                    chunk = chunk.replace(original_struct, updated_struct)
            else:
                print("  Warning: Could not find struct VertexOutput")

            # 4. Insert Geometry Function
            if 'void geom(' not in chunk:
                # Insert before frag function
                if 'half4 frag' in chunk:
                    chunk = chunk.replace('half4 frag', geom_func + '\n\t\t\thalf4 frag')
                elif 'float4 frag' in chunk:
                    chunk = chunk.replace('float4 frag', geom_func + '\n\t\t\tfloat4 frag')
            
            # 5. Patch Frag Function Return
            # FWGrass: return outColor;
            # FWTreeLeaf: return color;
            # We only patch if we haven't already
            
            if 'edgeIntensity' not in chunk:
                if 'return outColor;' in chunk:
                    chunk = chunk.replace('return outColor;', mix_logic + '\n\t\t\t\treturn lerp(_WireColor, outColor, edgeIntensity);')
                elif 'return color;' in chunk:
                    chunk = chunk.replace('return color;', mix_logic + '\n\t\t\t\treturn lerp(_WireColor, color, edgeIntensity);')
            
            patched_forward = True
        
        new_parts.append(chunk)

    final_content = 'HLSLPROGRAM'.join(new_parts)
    
    new_filename = filename.replace('.shader', '_Wireframe.shader')
    with open(new_filename, 'w') as f:
        f.write(final_content)
    print(f"Created {new_filename}")

base_path = r"c:\Users\whees\TheBlock\Assets\TriForge Assets\Fantasy Worlds - DEMO Common Files\Shaders"

patch_shader(os.path.join(base_path, "FWGrass.shader"), 9)
patch_shader(os.path.join(base_path, "FWTreeLeaf.shader"), 10)
patch_shader(os.path.join(base_path, "FWTreeBark.shader"), 10)
