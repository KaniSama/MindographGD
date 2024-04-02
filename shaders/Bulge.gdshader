shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

//const float zoom1 = 0.4;
//const float zoom2 = 0.2;
//const float zoom3 = 0.6;
//const float aberration = 0.05;
//const float contrast = 1.7;
//const float saturation = 0.75;
//const float gamma = 1.4;

#define zoom1 0.88
#define zoom2 0.15
#define zoom3 0.7
#define aberration 0.02
#define contrast 1.0
#define saturation 0.75
#define gamma 1.0

uniform bool enable_col_adjust = true;
uniform bool enable_aberation = true;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Bulge calculation
	float dist = length(uv - 0.5); // distance to the center
	float offset = dist * ((zoom2 * dist / zoom3) + zoom1); // offset as if it wasn't a circle
	vec2 sample = normalize(uv - 0.5) * offset + 0.5; // normalize vector to get the offset
	
	vec4 base_col = texture(screen_texture, uv).rgba;
	
	// Chromatic aberration
	if (enable_aberation) {
		vec2 abr_dist = (uv - 0.5) * (uv - 0.5) * aberration; // square curve so there's no aberration at the center
		base_col.rgb = texture(screen_texture, sample).rgb * vec3(0.0, 1.0, 0.0) + 
			texture(screen_texture, sample + abr_dist).rgb * vec3(0.0, 0.0, 1.0) +
			texture(screen_texture, sample - abr_dist).rgb * vec3(1.0, 0.0, 0.0);
	}
	
	// gamma, contrast & saturation:
	if (enable_col_adjust) {
		base_col.rgb = pow(base_col.rgb, vec3(1.0 / gamma));
		base_col.rgb = (base_col.rgb - 0.5) * contrast + 0.5;
		float gray = dot(base_col.rgb, vec3(0.33,0.33,00.33));
		base_col.rgb = mix(vec3(gray), base_col.rgb, saturation);
	}
	
	// Output
	COLOR = base_col;
}
