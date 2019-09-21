#version 400
#extension GL_ARB_shading_language_include : require
#include "/model-globals.glsl"

uniform vec3 worldCameraPosition;
uniform vec3 worldLightPosition;
uniform vec3 diffuseColor;
uniform sampler2D diffuseTexture;
uniform bool wireframeEnabled;
uniform vec4 wireframeLineColor;

in fragmentData
{
	vec3 position;
	vec3 normal;
	vec2 texCoord;
	noperspective vec3 edgeDistance;
} fragment;

out vec4 fragColor;

void main()
{
	float i = 0.8;
	float ambient = 0.3;
	float diffuse = 0.3;
	float specular = 0.5;
	float shininess = 0.5;

	vec3 L = normalize(worldLightPosition-fragment.position);
	vec3 R = normalize(2*dot(L,fragment.normal)*fragment.normal-L);
	vec3 V = normalize(worldCameraPosition - fragment.position);



	float light =  clamp(diffuse*dot(L,fragment.normal)*i,0,1) + clamp(specular*pow(dot(R,V),shininess)*i,0,1);


	vec4 result = vec4(light, light, light, 1.0)+ambient*vec4(1.0);

	if (wireframeEnabled)
	{
		float smallestDistance = min(min(fragment.edgeDistance[0], fragment.edgeDistance[1]), fragment.edgeDistance[2]);
		float edgeIntensity = exp2(-1.0 * smallestDistance * smallestDistance);
		result.rgb = mix(result.rgb, wireframeLineColor.rgb, edgeIntensity * wireframeLineColor.a);
	}

	fragColor = result;
}