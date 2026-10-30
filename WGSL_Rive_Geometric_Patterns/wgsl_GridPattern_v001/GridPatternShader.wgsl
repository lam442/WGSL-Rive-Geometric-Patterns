struct Params {
    thickness_x: f32,
    thickness_y: f32,
    spacing_x: f32,
    spacing_y: f32,
    offset_x: f32,
    offset_y: f32,
    _pad0: f32,
    _pad1: f32,
    grid_color: vec4<f32>,
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
    let p = frag_coord.xy - vec2<f32>(params.offset_x, params.offset_y);
    let cell = (p - floor(p / spacing) * spacing) - spacing * 0.5;

    let d_vert = abs(cell.x) - max(params.thickness_x, 0.0) * 0.5;
    let d_horz = abs(cell.y) - max(params.thickness_y, 0.0) * 0.5;
    let dist = min(d_vert, d_horz);

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.grid_color.a;
    return vec4<f32>(params.grid_color.rgb * alpha, alpha);
}
