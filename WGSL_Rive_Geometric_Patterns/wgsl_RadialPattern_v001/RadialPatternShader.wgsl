struct Params {
    center_x: f32,
    center_y: f32,
    ring_spacing: f32,
    ring_thickness: f32,
    ray_count: f32,
    ray_thickness: f32,
    rotation: f32,
    _pad: f32,
    radial_color: vec4<f32>,
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
    let p = frag_coord.xy - vec2<f32>(params.center_x, params.center_y);
    let r = length(p);

    var d_ring = 1e6;
    if (params.ring_spacing > 0.5 && params.ring_thickness > 0.0) {
        let sp = params.ring_spacing;
        let cell_r = (r - floor(r / sp) * sp) - sp * 0.5;
        d_ring = abs(cell_r) - params.ring_thickness * 0.5;
    }

    var d_ray = 1e6;
    let n_rays = floor(params.ray_count);
    if (n_rays >= 1.0 && params.ray_thickness > 0.0) {
        let rad = params.rotation * 0.017453292519943295;
        let ang = atan2(p.y, p.x) - rad;
        let sector = 6.283185307179586 / n_rays;
        let a_mod = (ang - floor(ang / sector) * sector) - sector * 0.5;
        d_ray = r * sin(abs(a_mod)) - params.ray_thickness * 0.5;
    }

    let dist = min(d_ring, d_ray);
    let alpha = (1.0 - smoothstep(-0.75, 0.75, dist)) * params.radial_color.a;
    return vec4<f32>(params.radial_color.rgb * alpha, alpha);
}
