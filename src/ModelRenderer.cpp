#include "ModelRenderer.h"
#include <globjects/base/File.h>
#include <globjects/State.h>
#include <iostream>
#include <filesystem>
#include <imgui.h>
#include "Viewer.h"
#include "Scene.h"
#include "Model.h"
#include <sstream>

#include <glm/gtc/type_ptr.hpp>
#include <glm/gtc/matrix_transform.hpp>

#define GLM_ENABLE_EXPERIMENTAL
#include <glm/gtx/string_cast.hpp>

using namespace minity;
using namespace gl;
using namespace glm;
using namespace globjects;

ModelRenderer::ModelRenderer(Viewer* viewer) : Renderer(viewer)
{
	m_lights = { vec3(-0.7f,0.7f,2.0f), vec3(0.5f,0.0f,2.0f),vec3(0.0f,1.5f,-3.0f) };
	m_lightVertices->setStorage(m_lights, GL_NONE_BIT);
	auto lightVertexBinding = m_lightArray->binding(0);
	lightVertexBinding->setBuffer(m_lightVertices.get(), 0, sizeof(vec3));
	lightVertexBinding->setFormat(3, GL_FLOAT);
	m_lightArray->enable(0);
	m_lightArray->unbind();

	createShaderProgram("model-base", {
		{ GL_VERTEX_SHADER,"./res/model/model-base-vs.glsl" },
		{ GL_GEOMETRY_SHADER,"./res/model/model-base-gs.glsl" },
		{ GL_FRAGMENT_SHADER,"./res/model/model-base-fs.glsl" },
		}, 
		{ "./res/model/model-globals.glsl" });

	createShaderProgram("tangent-base", {
		{ GL_VERTEX_SHADER,"./res/model/tangent-base-vs.glsl" },
		{ GL_GEOMETRY_SHADER,"./res/model/tangent-base-gs.glsl" },
		{ GL_FRAGMENT_SHADER,"./res/model/tangent-base-fs.glsl" },
		},
		{ "./res/model/model-globals.glsl" });

	createShaderProgram("model-light", {
		{ GL_VERTEX_SHADER,"./res/model/model-light-vs.glsl" },
		{ GL_FRAGMENT_SHADER,"./res/model/model-light-fs.glsl" },
		}, { "./res/model/model-globals.glsl" });
}

void ModelRenderer::display()
{
	// Save OpenGL state
	auto currentState = State::currentState();

	// retrieve/compute all necessary matrices and related properties
	const mat4 viewMatrix = viewer()->viewTransform();
	const mat4 inverseViewMatrix = inverse(viewMatrix);
	const mat4 modelViewMatrix = viewer()->modelViewTransform();
	const mat4 inverseModelViewMatrix = inverse(modelViewMatrix);
	const mat4 modelLightMatrix = viewer()->modelLightTransform();
	const mat4 inverseModelLightMatrix = inverse(modelLightMatrix);
	const mat4 modelViewProjectionMatrix = viewer()->modelViewProjectionTransform();
	const mat4 inverseModelViewProjectionMatrix = inverse(modelViewProjectionMatrix);
	const mat4 projectionMatrix = viewer()->projectionTransform();
	const mat4 inverseProjectionMatrix = inverse(projectionMatrix);
	const mat3 normalMatrix = mat3(transpose(inverseModelViewMatrix));
	const mat3 inverseNormalMatrix = inverse(normalMatrix);
	const vec2 viewportSize = viewer()->viewportSize();

	auto shaderProgramModelBase = shaderProgram("model-base");

	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);

	viewer()->scene()->model()->vertexArray().bind();

	const std::vector<Group> & groups = viewer()->scene()->model()->groups();
	const std::vector<Material> & materials = viewer()->scene()->model()->materials();

	static std::vector<bool> groupEnabled(groups.size(), true);
	static bool wireframeEnabled = true;
	static bool lightSourceEnabled[3] = { true,true,true };
	static bool enableIllumination;
	static int normalMapping = 0;
	static bool tangentSpace;

	static float diffuse=0.5;
	static float specular=0.5;
	static float shininess=20;
	
	static vec4 wireframeLineColor = vec4(1.0f);

	if (ImGui::BeginMenu("Model"))
	{
		ImGui::Checkbox("Wireframe Enabled", &wireframeEnabled);

		if (wireframeEnabled)
		{
			if (ImGui::CollapsingHeader("Wireframe"))
			{
				ImGui::ColorEdit4("Line Color", (float*)&wireframeLineColor, ImGuiColorEditFlags_AlphaBar);
			}
		}

		if (ImGui::CollapsingHeader("Groups"))
		{
			for (uint i = 0; i < groups.size(); i++)
			{
				bool checked = groupEnabled.at(i);
				ImGui::Checkbox(groups.at(i).name.c_str(), &checked);
				groupEnabled[i] = checked;
			}

		}
		if (ImGui::CollapsingHeader("Illumination"))
		{
			ImGui::Checkbox("Enable illumination", &enableIllumination);
			ImGui::Checkbox("key light", &lightSourceEnabled[0]);
			ImGui::Checkbox("fill light", &lightSourceEnabled[1]);
			ImGui::Checkbox("back light", &lightSourceEnabled[2]);
			ImGui::SliderFloat("difuse", &diffuse, 0.0f, 1.0f);
			ImGui::SliderFloat("specular", &specular, 0.0f, 1.0f);
			ImGui::SliderFloat("shiness", &shininess, 0.0f, 50.0f);
			if(ImGui::CollapsingHeader("normal mapping")){
				ImGui::RadioButton("No normal mapping", &normalMapping, 0);
				ImGui::RadioButton("Procedural bumpmapping", &normalMapping, 1);
				ImGui::RadioButton("Bumpmap texture", &normalMapping, 2);
				ImGui::Checkbox("Tangentspace light computation", &tangentSpace);

			}
		}
		ImGui::EndMenu();
	}

	if (tangentSpace) {
		auto shaderProgramModelBase = shaderProgram("tangent-base");
	}


	vec4 objectCameraPosition = inverseModelViewMatrix * vec4(0.0f, 0.0f, 0.0f, 1.0f);
	vec4 LightPosition = inverseModelLightMatrix * vec4(m_lights.at(1), 1.0f);
	
	std::vector <glm::vec3> objectLights;
	std::vector <bool> lightEnabled;
	for (vec3 v : m_lights) {
		vec4 a = inverseModelLightMatrix * vec4(v, 1.0f);
		objectLights.push_back(vec3(a));
	}
	for (int i = 0; i < 3; i++) {
		lightEnabled.push_back(lightSourceEnabled[i]);
	}

	shaderProgramModelBase->setUniform("modelViewProjectionMatrix", modelViewProjectionMatrix);
	shaderProgramModelBase->setUniform("viewportSize", viewportSize);
	shaderProgramModelBase->setUniform("worldCameraPosition", vec3(objectCameraPosition));
	shaderProgramModelBase->setUniform("worldLightPosition", vec3(LightPosition));
	shaderProgramModelBase->setUniform("wireframeEnabled", wireframeEnabled);
	shaderProgramModelBase->setUniform("wireframeLineColor", wireframeLineColor);

	shaderProgramModelBase->setUniform("diffuse", diffuse);
	shaderProgramModelBase->setUniform("specular", specular);
	shaderProgramModelBase->setUniform("shininess", shininess);

	shaderProgramModelBase->setUniform("normalMapping", normalMapping);

	shaderProgramModelBase->setUniform("WorldLightPositions", objectLights);
	shaderProgramModelBase->setUniform("WorldLights", lightEnabled);

	shaderProgramModelBase->use();

	for (uint i = 0; i < groups.size(); i++)
	{
		if (groupEnabled.at(i))
		{
			const Material & material = materials.at(groups.at(i).materialIndex);

			shaderProgramModelBase->setUniform("diffuseColor", material.diffuse);
			shaderProgramModelBase->setUniform("materialSpecular", material.specular);

			if (material.diffuseTexture)
			{
				shaderProgramModelBase->setUniform("diffuseTexture", 0);
				material.diffuseTexture->bindActive(0);
			}

			if (material.specularTexture)
			{
				shaderProgramModelBase->setUniform("specularTexture", 1);
				material.specularTexture->bindActive(1);
			}

			if (material.shininessTexture)
			{
				shaderProgramModelBase->setUniform("shininessTexture", 2);
				material.shininessTexture->bindActive(2);
			}
			if (material.bumpTexture)
			{
				shaderProgramModelBase->setUniform("bumpTexture", 3);
				material.bumpTexture->bindActive(3);
			}

			viewer()->scene()->model()->vertexArray().drawElements(GL_TRIANGLES, groups.at(i).count(), GL_UNSIGNED_INT, (void*)(sizeof(GLuint)*groups.at(i).startIndex));
	
			if (material.diffuseTexture)
			{
				material.diffuseTexture->unbind();
			}
			if (material.specularTexture)
			{
				material.specularTexture->unbind();
			}

			if (material.shininessTexture)
			{
				material.shininessTexture->unbind();
			}
			if (material.bumpTexture)
			{
				material.bumpTexture->unbind();
			}
		}
	}
	shaderProgramModelBase->release();

	viewer()->scene()->model()->vertexArray().unbind();



	if (lightSourceEnabled[0]||lightSourceEnabled[1]||lightSourceEnabled[2])
	{
		auto shaderProgramModelLight = shaderProgram("model-light");
		shaderProgramModelLight->setUniform("modelViewProjectionMatrix", modelViewProjectionMatrix * inverseModelLightMatrix);
		shaderProgramModelLight->setUniform("viewportSize", viewportSize);

		glEnable(GL_PROGRAM_POINT_SIZE);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDepthMask(GL_FALSE);

		m_lightArray->bind();

		shaderProgramModelLight->use();
		for (int i = 0; i < 3;i++) {
			if (lightSourceEnabled[i]) {
				m_lightArray->drawArrays(GL_POINTS, i, 1);
			}
		}
		shaderProgramModelLight->release();

		m_lightArray->unbind();

		glDisable(GL_PROGRAM_POINT_SIZE);
		glDisable(GL_BLEND);
		glDepthMask(GL_TRUE);
	}

	// Restore OpenGL state (disabled to to issues with some Intel drivers)
	// currentState->apply();
}