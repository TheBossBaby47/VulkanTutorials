/******************************************************************************
This file is part of the Newcastle Vulkan Tutorial Series

Author:Rich Davison
Contact:richgdavison@gmail.com
License: MIT (see LICENSE file at the top of the source tree)
*//////////////////////////////////////////////////////////////////////////////
#pragma once
#include "VulkanTutorialRenderer.h"

namespace NCL::Rendering {
	class BasicTexturingRenderer : public VulkanTutorialRenderer	{
	public:
		BasicTexturingRenderer(Window& window);
		~BasicTexturingRenderer();

		void RenderFrame() override;

	protected:
		void	BuildPipeline();

		VulkanPipeline	texturePipeline;

		std::shared_ptr<VulkanShader>	defaultShader;
		std::shared_ptr<VulkanMesh>		defaultMesh;
		std::shared_ptr<VulkanTexture>	textures[2];

		vk::UniqueDescriptorSet			descriptorSets[2];
		vk::UniqueDescriptorSetLayout	descriptorLayout;
	};
}