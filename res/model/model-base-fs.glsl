#version 400
#extension GL_ARB_shading_language_include : require
#include "/model-globals.glsl"

uniform vec3 worldCameraPosition;
uniform vec3 worldLightPosition;
uniform vec3 diffuseColor;
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

vec3 bumpmap(float alpha, float beta){
	vec3 t = normalize(fragment.TBN[0]);
	vec3 b = normalize(fragment.TBN[1]);
	float sinu = sin(beta*fragment.texCoord.x);
	float sinv = sin(beta*fragment.texCoord.y);
	float cosu = cos(beta*fragment.texCoord.x);
	float cosv = cos(beta*fragment.texCoord.y);
	return normalize(fragment.normal + 2*alpha*beta*sinu*cosu*pow(sinv,2)*t+2*alpha*beta*sinv*cosv*pow(sinu,2)*b);
}





vec3 phongShading(vec3 lightPos,float str){
	
	vec3 i = vec3(0.8);
	float ambient = 0.3;
	vec3 normal = bumpmap(0.5,100);

	vec3 L = normalize(lightPos-fragment.position);
	vec3 R = normalize(2*dot(L,normal)*normal-L);
	vec3 V = normalize(worldCameraPosition - fragment.position);

	vec3 Kd = vec3(texture(diffuseTexture,fragment.texCoord));
	vec3 Ks = vec3(texture(specularTexture,fragment.texCoord));
	vec3 light =  str*clamp(diffuse*dot(L,normal)*Kd,0,1) + clamp(specular*Ks*pow(dot(R,V),shininess)*i,0,1);

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
	}

	fragColor = vec4(result,1.0);
}
