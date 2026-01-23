shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 albedo : source_color = vec4(0.0,0.0,0.0,1.0);
uniform float growth : hint_range(0.0, 0.1) = 0.01; // How much to "inflate" the box

void vertex() {
    // Standard block corner is (0,0,0) to (1,1,1)
    // We shift the vertex away from the center of the block (0.5, 0.5, 0.5)
    vec3 center = vec3(0.5);
    vec3 direction = VERTEX - center;
    
    // Push the vertex outward slightly
    vec3 expanded_vertex = VERTEX + (normalize(direction) * growth);
    
    POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(expanded_vertex, 1.0);
	COLOR = albedo;
}

void fragment() {
    ALBEDO = albedo.rgb;
}