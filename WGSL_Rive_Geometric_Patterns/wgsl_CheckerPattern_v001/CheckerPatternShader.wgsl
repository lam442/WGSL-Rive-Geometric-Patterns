struct Params {
    spacing_x: f32,
    spacing_y: f32,
    angle: f32,
    _pad: f32,
    checker_color: vec4<f32>,
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
    let rad = -params.angle * 0.017453292519943295;
    let c = cos(rad);
    let s = sin(rad);
    let p = vec2<f32>(
        frag_coord.x * c - frag_coord.y * s,
        frag_coord.x * s + frag_coord.y * c,
    );

    let uv = p / spacing;
    let cell = floor(uv);
    let f = (uv - cell) - vec2<f32>(0.5, 0.5);

    let d_edge = (vec2<f32>(0.5, 0.5) - abs(f)) * spacing;
    let min_d = min(d_edge.x, d_edge.y);

    let parity = abs((cell.x + cell.y) - floor((cell.x + cell.y) * 0.5) * 2.0);
    let sign_p = select(-1.0, 1.0, parity < 0.5);
    let signed_dist = sign_p * min_d;

    let mask = smoothstep(-0.75, 0.75, signed_dist);
    let alpha = mask * params.checker_color.a;
    return vec4<f32>(params.checker_color.rgb * alpha, alpha);
}
