/******************************************************************************
This file is part of the Newcastle Vulkan Tutorial Series

Author:Rich Davison
Contact:richgdavison@gmail.com
License: MIT (see LICENSE file at the top of the source tree)
*//////////////////////////////////////////////////////////////////////////////
#pragma once
#include "VulkanTutorialRenderer.h"

namespace NCL::Rendering {
	class BasicPushConstantRenderer : public VulkanTutorialRenderer {
	public:
		BasicPushConstantRenderer(Window& window);
		~BasicPushConstantRenderer();

		void RenderFrame()		override;

	protected:
		void	BuildPipeline();

		VulkanMesh* triMesh;
		VulkanShader* basicShader;

		VulkanPipeline	basicPipeline;

		Vector4	colourUniform;
		Vector3 positionUniform;
	};
}