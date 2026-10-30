struct Params {
    min_radius: f32,
    max_radius: f32,
    angle: f32,
    spacing_x: f32,
    spacing_y: f32,
    stagger: f32,
    canvas_w: f32,
    canvas_h: f32,
    halftone_color: vec4<f32>,
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
    let shift_x = row_odd * (params.stagger * 0.01) * spacing.x;
    let p_stag = vec2<f32>(frag_coord.x - shift_x, frag_coord.y);

    let cell_idx = floor(p_stag / spacing);
    let cell_pos = (p_stag - cell_idx * spacing) - spacing * 0.5;
    let cell_center = vec2<f32>(
        (cell_idx.x + 0.5) * spacing.x + shift_x,
        (cell_idx.y + 0.5) * spacing.y,
    );

    let dims = max(vec2<f32>(params.canvas_w, params.canvas_h), vec2<f32>(1.0, 1.0));
    let center = dims * 0.5;
    let rad = params.angle * 0.017453292519943295;
    let dir = vec2<f32>(cos(rad), sin(rad));
    let span = max(abs(dir.x) * dims.x + abs(dir.y) * dims.y, 1.0);

    let t = clamp(dot(cell_center - center, dir) / span + 0.5, 0.0, 1.0);
    let r = mix(params.min_radius, params.max_radius, t);

    let dist = length(cell_pos) - max(r, 0.0);
    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.halftone_color.a;
    return vec4<f32>(params.halftone_color.rgb * alpha, alpha);
}
