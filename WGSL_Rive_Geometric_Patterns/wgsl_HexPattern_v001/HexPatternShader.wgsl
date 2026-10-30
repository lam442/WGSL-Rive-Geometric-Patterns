struct Params {
    cell_size: f32,
    gap: f32,
    corner_radius: f32,
    rotation: f32,
    hex_color: vec4<f32>,
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

fn sd_hex(p_in: vec2<f32>, r: f32) -> f32 {
    let k = vec3<f32>(-0.866025404, 0.5, 0.577350269);
    var p = abs(p_in);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2<f32>(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let scale = max(params.cell_size, 2.0);
    let rad = -params.rotation * 0.017453292519943295;
    let c = cos(rad);
    let s = sin(rad);
    let p_rot = vec2<f32>(
        frag_coord.x * c - frag_coord.y * s,
        frag_coord.x * s + frag_coord.y * c,
    );

    let s_hex = vec2<f32>(1.732050808, 1.0) * scale;
    let h_hex = s_hex * 0.5;

    let a = (p_rot - floor(p_rot / s_hex) * s_hex) - h_hex;
    let p_b = p_rot - h_hex;
    let b = (p_b - floor(p_b / s_hex) * s_hex) - h_hex;

    let gv = select(b, a, dot(a, a) < dot(b, b));

    let inradius = max(scale * 0.433012702 - params.gap * 0.5, 0.0);
    let cr = clamp(params.corner_radius, 0.0, inradius);
    let dist = sd_hex(vec2<f32>(gv.y, gv.x), max(inradius - cr, 0.0)) - cr;

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.hex_color.a;
    return vec4<f32>(params.hex_color.rgb * alpha, alpha);
}
