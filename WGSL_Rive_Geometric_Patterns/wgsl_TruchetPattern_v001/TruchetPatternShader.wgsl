struct Params {
    cell_size: f32,
    thickness: f32,
    seed: f32,
    rotation: f32,
    truchet_color: vec4<f32>,
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

fn hash21(p_in: vec2<f32>, seed: f32) -> f32 {
    var p = fract((p_in + vec2<f32>(seed * 17.31, seed * 43.17)) * vec2<f32>(234.34, 435.345));
    p += dot(p, p + vec2<f32>(34.23, 34.23));
    return fract(p.x * p.y);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let cs = max(params.cell_size, 4.0);
    let rad = -params.rotation * 0.017453292519943295;
    let c = cos(rad);
    let s = sin(rad);
    let p_rot = vec2<f32>(
        frag_coord.x * c - frag_coord.y * s,
        frag_coord.x * s + frag_coord.y * c,
    );

    let uv = p_rot / cs;
    let cell = floor(uv);
    var gv = (uv - cell) - vec2<f32>(0.5, 0.5);

    let rnd = hash21(cell, params.seed);
    if (rnd > 0.5) {
        gv.x = -gv.x;
    }

    let d1 = abs(length(gv - vec2<f32>(0.5, 0.5)) - 0.5);
    let d2 = abs(length(gv - vec2<f32>(-0.5, -0.5)) - 0.5);
    let dist = min(d1, d2) * cs - max(params.thickness, 0.0) * 0.5;

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.truchet_color.a;
    return vec4<f32>(params.truchet_color.rgb * alpha, alpha);
}
