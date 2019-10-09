#version 400
#extension GL_ARB_shading_language_include : require
#include "/model-globals.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

uniform vec2 viewportSize;

in vertexData
{
	vec3 position;
	vec3 normal;
	vec2 texCoord;
} vertices[];

out fragmentData
{
	vec3 position;
	vec3 normal;
	vec2 texCoord;
	noperspective vec3 edgeDistance;
	mat3 TBN;
} fragment;

void main(void)
{
	vec3 edge1 = vertices[1].position - vertices[0].position;
	vec3 edge2 = vertices[2].position - vertices[0].position;
	vec2 deltaUV1 = vertices[1].texCoord - vertices[0].texCoord;
	vec2 deltaUV2 = vertices[2].texCoord - vertices[0].texCoord;
	float f=1.0f / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);
	vec3 tangent;
	tangent.x = f * (deltaUV2.y * edge1.x - deltaUV1.y * edge2.x);
	tangent.y = f * (deltaUV2.y * edge1.y - deltaUV1.y * edge2.y);
	tangent.z = f * (deltaUV2.y * edge1.z - deltaUV1.y * edge2.z);
	vec3 bitangent;
	bitangent.x = f * (-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x);
	bitangent.y = f * (-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y);
	bitangent.z = f * (-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z);
	vec3 normal = cross(tangent,bitangent);
	mat3 TBN = mat3(tangent,bitangent,normal);
	fragment.TBN = TBN;


	vec2 p[3];
	vec2 v[3];

	for (int i=0;i<3;i++)
		p[i] = 0.5 * viewportSize *  gl_in[i].gl_Position.xy/gl_in[i].gl_Position.w;

	v[0] = p[2]-p[1];
	v[1] = p[2]-p[0];
	v[2] = p[1]-p[0];

	float area = abs(v[1].x*v[2].y - v[1].y * v[2].x);

	for (int i=0;i<3;i++)
	{
		gl_Position = gl_in[i].gl_Position;
		fragment.position = vertices[i].position;
		fragment.normal = vertices[i].normal;
		fragment.texCoord = vertices[i].texCoord;
		
		vec3 ed = vec3(0.0);
		ed[i] = area / length(v[i]);
		fragment.edgeDistance = ed;

		EmitVertex();
	}

	EndPrimitive();
}