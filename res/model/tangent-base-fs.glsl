#version 400
#extension GL_ARB_shading_language_include : require
#include "/model-globals.glsl"

uniform vec3 worldCameraPosition;
uniform vec3 worldLightPosition;
uniform vec3 diffuseColor;
uniform vec3 materialSpecular;
uniform sampler2D diffuseTexture;
uniform sampler2D specularTexture;
uniform sampler2D shininessTexture;
uniform sampler2D bumpTexture;

uniform bool wireframeEnabled;
uniform vec4 wireframeLineColor;
uniform bool worldLights[];

uniform float diffuse;
uniform float specular;
uniform float shininess;
uniform int normalMapping;


uniform vec3 WorldLightPositions[];
uniform bool WorldLights[];
in fragmentData
{
	vec3 position;
	vec3 normal;
	vec2 texCoord;
	noperspective vec3 edgeDistance;
	mat3 TBN;
} fragment;

out vec4 fragColor;

vec3 bumpmap(float alpha, float beta) {
	vec3 t = normalize(fragment.TBN[0]);
	vec3 b = normalize(fragment.TBN[1]);
	float sinu = sin(beta * fragment.texCoord.x);
	float sinv = sin(beta * fragment.texCoord.y);
	float cosu = cos(beta * fragment.texCoord.x);
	float cosv = cos(beta * fragment.texCoord.y);
	return normalize(fragment.normal + 2 * alpha * beta * sinu * cosu * pow(sinv, 2) * t + 2 * alpha * beta * sinv * cosv * pow(sinu, 2) * b);
}
vec3 bumpmap2(float alpha, float beta) {
	vec3 n = (dot(fragment.TBN[2], fragment.normal) / dot(fragment.normal, fragment.normal)) * fragment.normal;
	vec3 b = cross(n, fragment.TBN[0]);
	vec3 t = cross(b, n);
	mat3 TBN = mat3(t, b, n);
	float sinu = sin(beta * fragment.texCoord.x);
	float sinv = sin(beta * fragment.texCoord.y);
	float cosu = cos(beta * fragment.texCoord.x);
	float cosv = cos(beta * fragment.texCoord.y);
	return normalize(fragment.normal + 2 * alpha * sinu * t + 2 * alpha * sinv * b);
}


vec3 phongShading(vec3 lightPos, float str) {
	vec3 n = (dot(fragment.TBN[2], fragment.normal) / dot(fragment.normal, fragment.normal)) * fragment.normal;
	vec3 b = cross(n, fragment.TBN[0]);
	vec3 t = cross(b, n);
	mat3 TBN = mat3(t, b, n);

	mat3 objToTangent = inverse(TBN);

	vec3 normal;
	if (normalMapping == 2) {
		normal = normalize(texture(bumpTexture, fragment.texCoord).xyz * 2.0 - 1.0);
	}
	else if (normalMapping == 0) {
		normal = normalize(objToTangent*fragment.normal);
	}
	else {
		normal = bumpmap2(0.05, 1000);
	}
	lightPos = objToTangent*lightPos;
	vec3 camera = objToTangent*worldCameraPosition;
	vec3 frag = objToTangent*fragment.position;

	vec3 L = normalize(lightPos - frag);
	vec3 R = normalize(2 * dot(L, normal) * normal - L);
	vec3 V = normalize(camera - frag);

	vec3 Kd = vec3(texture(diffuseTexture, fragment.texCoord));
	vec3 Ks = vec3(texture(specularTexture, fragment.texCoord));
	vec3 light = str * clamp(diffuse * dot(L, normal) * Kd, 0, 1) + clamp(specular * Ks * pow(dot(R, V), shininess), 0, 1);

	return light;
}
void main()
{
	vec3 result = vec3(0.0f);
	if (WorldLights[1]) {
		result = result + phongShading(WorldLightPositions[1], 0.5);
	}
	if (WorldLights[2]) {
		result = result + phongShading(WorldLightPositions[2], 0.2);
	}
	if (WorldLights[0]) {
		result = result + phongShading(WorldLightPositions[0], 0.2);
	}


	if (wireframeEnabled)
	{
		float smallestDistance = min(min(fragment.edgeDistance[0], fragment.edgeDistance[1]), fragment.edgeDistance[2]);
		float edgeIntensity = exp2(-1.0 * smallestDistance * smallestDistance);
		result.rgb = mix(result.rgb, wireframeLineColor.rgb, edgeIntensity * wireframeLineColor.a);
	}

	fragColor = vec4(result, 1.0);
}
