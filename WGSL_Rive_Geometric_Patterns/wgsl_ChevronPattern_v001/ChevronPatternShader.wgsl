struct Params {
    thickness: f32,
    spacing: f32,
    amplitude: f32,
    wavelength: f32,
    sharpness: f32,
    angle: f32,
    offset: f32,
    _pad: f32,
    chevron_color: vec4<f32>,
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
    let sp = max(params.spacing, 1.0);
    let wl = max(params.wavelength, 1.0);

    let rad = -params.angle * 0.017453292519943295;
    let c = cos(rad);
    let s = sin(rad);
    let p = vec2<f32>(
        frag_coord.x * c - frag_coord.y * s,
        frag_coord.x * s + frag_coord.y * c,
    );

    let u = p.x / wl;
    let f = u - floor(u);
    let tri = 1.0 - 4.0 * abs(f - 0.5);
    let sine = sin(u * 6.283185307179586);
    let sh = clamp(params.sharpness, 0.0, 1.0);
    let wave = mix(sine, tri, sh) * params.amplitude;

    let d_tri = (4.0 * params.amplitude) / wl;
    let d_sin = cos(u * 6.283185307179586) * (6.283185307179586 * params.amplitude / wl);
    let slope = mix(abs(d_sin), d_tri, sh);
    let norm_factor = sqrt(1.0 + slope * slope);

    let y_mod = p.y - wave - params.offset;
    let cell_y = (y_mod - floor(y_mod / sp) * sp) - sp * 0.5;
    let dist = (abs(cell_y) / norm_factor) - max(params.thickness, 0.0) * 0.5;

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.chevron_color.a;
    return vec4<f32>(params.chevron_color.rgb * alpha, alpha);
}
