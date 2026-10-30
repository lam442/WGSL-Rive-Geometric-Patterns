struct Params {
    radius: f32,
    spacing_x: f32,
    spacing_y: f32,
    stagger: f32,
    dot_color: vec4<f32>,
}

@group(0) @binding(0) var<uniform> params: Params;

@vertex
fn vs_main(@builtin(vertex_index) vid: u32) -> @builtin(position) vec4<f32> {
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0),
    );
    return vec4<f32>(pos[vid], 0.0, 1.0);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let spacing = max(
        vec2<f32>(params.spacing_x, params.spacing_y),
        vec2<f32>(1.0, 1.0),
    );
    let row = floor(frag_coord.y / spacing.y);
    let row_odd = row - floor(row * 0.5) * 2.0;
    let p_stag = vec2<f32>(frag_coord.x - row_odd * (params.stagger * 0.01) * spacing.x, frag_coord.y);
    let cell_pos = (p_stag - floor(p_stag / spacing) * spacing) - spacing * 0.5;
    let dist = length(cell_pos) - params.radius;

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.dot_color.a;
    return vec4<f32>(params.dot_color.rgb * alpha, alpha);
}
