#version 400
#extension GL_ARB_shading_language_include : require
#include "/model-globals.glsl"

uniform vec3 worldCameraPosition;
uniform vec3 worldLightPosition;
uniform vec3 diffuseColor;
uniform sampler2D diffuseTexture;
uniform bool wireframeEnabled;
uniform vec4 wireframeLineColor;
uniform bool worldLights[];

uniform float diffuse;
uniform float specular;
uniform float shininess;

uniform vec3 WorldLightPositions[];
uniform bool WorldLights[];
in fragmentData
{
	vec3 position;
	vec3 normal;
	vec2 texCoord;
	noperspective vec3 edgeDistance;
} fragment;

out vec4 fragColor;

vec3 phongShading(vec3 lightPos,float str){
	
	vec3 i = vec3(0.8);
	float ambient = 0.3;

	vec3 L = normalize(lightPos-fragment.position);
	vec3 R = normalize(2*dot(L,fragment.normal)*fragment.normal-L);
	vec3 V = normalize(worldCameraPosition - fragment.position);

	vec3 ambientLight = vec3(texture(diffuseTexture,fragment.texCoord));

	vec3 light =  str*clamp(diffuse*dot(L,fragment.normal)*ambientLight,0,1) + clamp(specular*pow(dot(R,V),shininess)*i,0,1);

	return light;
}
void main()
{
vec3 result = vec3(0.0f);
	if(WorldLights[1]){
		result = result+phongShading(WorldLightPositions[1],0.5);
	}
	if(WorldLights[2]){
		result = result+phongShading(WorldLightPositions[2],0.2);
	}
	if(WorldLights[0]){
		result = result+phongShading(WorldLightPositions[0],0.2);
	}


	if (wireframeEnabled)
	{
		float smallestDistance = min(min(fragment.edgeDistance[0], fragment.edgeDistance[1]), fragment.edgeDistance[2]);
		float edgeIntensity = exp2(-1.0 * smallestDistance * smallestDistance);
		result.rgb = mix(result.rgb, wireframeLineColor.rgb, edgeIntensity * wireframeLineColor.a);
		result.rgb = phongShading(WorldLightPositions[1],0);
			if(WorldLights[1]){
					result = result+phongShading(WorldLightPositions[1],0.5);
				}
				if(WorldLights[2]){
					result = result+phongShading(WorldLightPositions[2],0.2);
				}
				if(WorldLights[0]){
					result = result+phongShading(WorldLightPositions[0],0.2);
				}
	}

	fragColor = vec4(result,1.0);
}
