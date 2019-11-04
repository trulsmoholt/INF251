#pragma once
#include "Renderer.h"
#include <memory>

#include <glm/glm.hpp>
#include <glbinding/gl/gl.h>
#include <glbinding/gl/enum.h>
#include <glbinding/gl/functions.h>

#include <globjects/VertexArray.h>
#include <globjects/VertexAttributeBinding.h>
#include <globjects/Buffer.h>
#include <globjects/Program.h>
#include <globjects/Shader.h>
#include <globjects/Framebuffer.h>
#include <globjects/Renderbuffer.h>
#include <globjects/Texture.h>
#include <globjects/base/File.h>
#include <globjects/TextureHandle.h>
#include <globjects/NamedString.h>
#include <globjects/base/StaticStringSource.h>
#include <chrono>


namespace minity
{
	struct ControlPoint {
		float time;
		float exploadedView;
	};
	class Viewer;

	class ModelRenderer : public Renderer
	{
	public:
		ModelRenderer(Viewer *viewer);
		virtual void display();

	private:
		void interpolateVector(float t, const glm::vec3 &p1, const glm::vec3 p2, glm::vec3 &np);
		void interpolateScalar(float t, std::vector<minity::ControlPoint> &controlPoints, ControlPoint &output, float tspan);

		std::vector<minity::ControlPoint> m_controlPoints;
		std::vector <glm::vec3> m_lights;
		std::unique_ptr<globjects::VertexArray> m_lightArray = std::make_unique<globjects::VertexArray>();
		std::unique_ptr<globjects::Buffer> m_lightVertices = std::make_unique<globjects::Buffer>();
		std::chrono::time_point<std::chrono::high_resolution_clock> m_startTime;
	};

}