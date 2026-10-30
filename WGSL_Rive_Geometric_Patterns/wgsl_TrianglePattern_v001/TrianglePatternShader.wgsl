struct Params {
    radius: f32,
    corner_radius: f32,
    rotation: f32,
    spacing_x: f32,
    spacing_y: f32,
    stagger: f32,
    _pad1: f32,
    _pad2: f32,
    triangle_color: vec4<f32>,
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

    let rad = -params.rotation * 0.017453292519943295;
    let c = cos(rad);
    let s = sin(rad);
    let p_rot = vec2<f32>(
        cell_pos.x * c - cell_pos.y * s,
        cell_pos.x * s + cell_pos.y * c,
    );

    let r_full = max(params.radius, 0.0);
    let cr = clamp(params.corner_radius, 0.0, r_full * 0.5);
    let r = max(r_full - cr * 2.0, 0.0) * 0.8660254037844386;

    let k = 1.7320508075688772;
    var p = vec2<f32>(abs(p_rot.x) - r, -p_rot.y + r / k);
    if (p.x + k * p.y > 0.0) {
        p = vec2<f32>(p.x - k * p.y, -k * p.x - p.y) * 0.5;
    }
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    let dist = -length(p) * sign(p.y) - cr;

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.triangle_color.a;
    return vec4<f32>(params.triangle_color.rgb * alpha, alpha);
}
