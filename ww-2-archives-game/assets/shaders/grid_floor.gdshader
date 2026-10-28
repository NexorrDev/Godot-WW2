shader_type spatial;

// Shader de sol avec grille métrique de 1 mètre et zone centrale délimitée
// 100% compatible Godot 4 (GL Compatibility)

uniform vec3 base_color : source_color = vec3(0.68, 0.70, 0.72);
uniform vec3 room_color : source_color = vec3(0.82, 0.84, 0.86); // Zone centrale plus claire pour la pièce
uniform vec3 grid_line_color : source_color = vec3(0.35, 0.38, 0.42);

void fragment() {
    // Coordonnées du monde en mètres
    vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
    
    // Grille tous les 1 mètre
    vec2 cell = fract(world_pos);
    float line_x = step(0.96, cell.x) + step(cell.x, 0.04);
    float line_z = step(0.96, cell.y) + step(cell.y, 0.04);
    float is_grid = clamp(line_x + line_z, 0.0, 1.0);
    
    // Délimitation de la zone de la future pièce (6m x 5.4m)
    bool inside_room = (abs(world_pos.x) <= 3.0) && (abs(world_pos.y) <= 2.7);
    vec3 tile_color = inside_room ? room_color : base_color;
    
    ALBEDO = mix(tile_color, grid_line_color, is_grid * 0.6);
    ROUGHNESS = 0.85;
}
