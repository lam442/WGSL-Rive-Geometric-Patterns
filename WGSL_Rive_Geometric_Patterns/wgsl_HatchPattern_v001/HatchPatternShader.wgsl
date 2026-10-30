struct Params {
    thickness_a: f32,
    thickness_b: f32,
    spacing_a: f32,
    spacing_b: f32,
    angle_a: f32,
    angle_b: f32,
    offset_a: f32,
    offset_b: f32,
    hatch_color: vec4<f32>,
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
    let sp_a = max(params.spacing_a, 1.0);
    let rad_a = params.angle_a * 0.017453292519943295;
    let n_a = vec2<f32>(-sin(rad_a), cos(rad_a));
    let proj_a = dot(frag_coord.xy, n_a) - params.offset_a;
    let cell_a = (proj_a - floor(proj_a / sp_a) * sp_a) - sp_a * 0.5;
    let d_a = abs(cell_a) - max(params.thickness_a, 0.0) * 0.5;

    let sp_b = max(params.spacing_b, 1.0);
    let rad_b = params.angle_b * 0.017453292519943295;
    let n_b = vec2<f32>(-sin(rad_b), cos(rad_b));
    let proj_b = dot(frag_coord.xy, n_b) - params.offset_b;
    let cell_b = (proj_b - floor(proj_b / sp_b) * sp_b) - sp_b * 0.5;
    let d_b = abs(cell_b) - max(params.thickness_b, 0.0) * 0.5;

    let dist = min(d_a, d_b);
    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.hatch_color.a;
    return vec4<f32>(params.hatch_color.rgb * alpha, alpha);
}
