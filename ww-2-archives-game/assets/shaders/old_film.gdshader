shader_type canvas_item;

// Shader d'effet vieille pellicule cinéma 1940s
// Compatible Godot 4 (GL Compatibility & Forward+)

uniform float grain_strength : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float scanlines_strength : hint_range(0.0, 1.0) = 0.15;
uniform float flicker_speed : hint_range(0.0, 30.0) = 15.0;
uniform vec4 tint_color : source_color = vec4(0.85, 0.78, 0.65, 1.0); // Teinte sépia archives

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Léger scintillement de projecteur d'époque
    float flicker = sin(TIME * flicker_speed) * 0.04 + 0.96;
    
    // Bruit de pellicule (grain)
    float grain = random(uv + vec2(sin(TIME * 20.0), cos(TIME * 15.0))) * grain_strength;
    
    // Lignes de balayage / rayures subtiles
    float scanline = sin(uv.y * 300.0) * scanlines_strength;
    
    // Vignette (bords sombres)
    vec2 center = uv - 0.5;
    float dist = length(center);
    float vignette = clamp(1.0 - dist * vignette_strength, 0.0, 1.0);
    
    // Rayure verticale aléatoire qui saute
    float scratch = 0.0;
    float scratch_x = fract(sin(floor(TIME * 6.0) * 43.12) * 98.4);
    if (abs(uv.x - scratch_x) < 0.0015) {
        scratch = 0.2;
    }
    
    // Composition finale
    vec3 base_color = tint_color.rgb * flicker;
    base_color += vec3(grain - scanline + scratch);
    base_color *= vignette;
    
    COLOR = vec4(base_color, 0.45); // Transparence pour voir le fond ou la fiche
}
