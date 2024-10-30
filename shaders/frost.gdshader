shader_type canvas_item;

uniform float frostyness = 2.0;
uniform float colorize = 1.0;
uniform vec4 frost_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);

float rand(vec2 uv) {

    float a = dot(uv, vec2(92., 80.));
    float b = dot(uv, vec2(41., 62.));

    float x = sin(a) + cos(b) * 51.;
    return fract(x);
}

void fragment() {
	// Get the texture
    vec4 frost_texture = texture(TEXTURE, UV);
	// rnd is a vec2 of randomized R and B channel
	vec2 rnd = vec2(
		rand(UV+frost_texture.r*.05),
		rand(UV+frost_texture.b*.05)
	);

    //vignette
    vec2 lensRadius = vec2(0.975, 0.01);
    float dist = distance(UV.xy, vec2(0.5,0.5));
    float vigfin = pow(1.-smoothstep(lensRadius.x, lensRadius.y, dist),2.);

    //rnd *= .025*vigfin + frost_texture.rg*frostyness*vigfin;
	vec2 frost = .025*vigfin + frost_texture.rg*frostyness*vigfin;
    //rnd *= .025*vigfin+d.rg*FROSTYNESS*abs(sin(iTime*.5))*vigfin;
    //UV += rnd;
    COLOR = mix(COLOR, frost_color, colorize*vec4(frost.r));
}
