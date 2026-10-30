struct Params {
    thickness: f32,
    spacing: f32,
    angle: f32,
    offset: f32,
    line_color: vec4<f32>,
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
    let rad = params.angle * 0.017453292519943295;
    let normal = vec2<f32>(-sin(rad), cos(rad));

    let proj = dot(frag_coord.xy, normal) - params.offset;
    let cell = (proj - floor(proj / sp) * sp) - sp * 0.5;
    let dist = abs(cell) - max(params.thickness, 0.0) * 0.5;

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.line_color.a;
    return vec4<f32>(params.line_color.rgb * alpha, alpha);
}
