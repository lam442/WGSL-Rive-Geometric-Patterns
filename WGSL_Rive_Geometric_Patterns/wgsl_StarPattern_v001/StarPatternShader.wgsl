struct Params {
    points: f32,
    outer_radius: f32,
    inner_radius: f32,
    corner_radius: f32,
    rotation: f32,
    spacing_x: f32,
    spacing_y: f32,
    stagger: f32,
    star_color: vec4<f32>,
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

    let n = max(floor(params.points), 3.0);
    let r_out = max(params.outer_radius, 0.5);
    let r_in = clamp(params.inner_radius, 0.1, r_out);

    let an = 3.141592653589793 / n;
    let p_up = vec2<f32>(p_rot.x, -p_rot.y);
    let ang = atan2(p_up.x, p_up.y) + an;
    let two_an = 2.0 * an;
    let bn = (ang - floor(ang / two_an) * two_an) - an;
    var p = length(p_up) * vec2<f32>(cos(bn), abs(sin(bn)));

    let v0 = vec2<f32>(r_out, 0.0);
    let v1 = r_in * vec2<f32>(cos(an), sin(an));
    let e = v1 - v0;
    let w = p - v0;
    let h = clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    let d_seg = length(w - e * h);
    let sgn = sign(w.x * e.y - w.y * e.x);
    let dist = d_seg * sgn - params.corner_radius;

    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.star_color.a;
    return vec4<f32>(params.star_color.rgb * alpha, alpha);
}
