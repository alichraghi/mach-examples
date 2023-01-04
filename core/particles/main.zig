const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

pub const App = @This();

const num_particles = 1_000_000;
const particle_position_offset = 0;
const particle_color_offset = 4 * 4;
const particle_instance_byte_size =
    3 * 4 + // position
    1 * 4 + // lifetime
    4 * 4 + // color
    3 * 4 + // velocity
    1 * 4 + // padding
    0;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

core: mach.Core,
pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,

pub fn init(app: *App) !void {
    app.core = try mach.Core.init(gpa.allocator(), .{});

    const frag_module = app.core.device().createShaderModuleWGSL("frag.wgsl", @embedFile("frag.wgsl"));
    const vert_module = app.core.device().createShaderModuleWGSL("vert.wgsl", @embedFile("vert.wgsl"));
    const probability_map = app.core.device().createShaderModuleWGSL("probability_map.wgsl", @embedFile("probability_map.wgsl"));
    _ = probability_map;

    const particles_buffer = app.core.device().createBuffer(&.{
        .size = num_particles * particle_instance_byte_size,
        .usage = .{ .vertex = true, .storage = true },
    });
    _ = particles_buffer;

    const render_pipeline = app.core.device().createRenderPipeline(&gpu.RenderPipeline.Descriptor{
        .layout = null,
        .vertex = gpu.VertexState.init(.{
            .module = vert_module,
            .entry_point = "main",
            .buffers = &.{
                gpu.VertexBufferLayout.init(.{
                    // instanced particles buffer
                    .array_stride = particle_instance_byte_size,
                    .step_mode = .instance,
                    .attributes = &.{
                        .{
                            // position
                            .shader_location = 0,
                            .offset = particle_position_offset,
                            .format = .float32x3,
                        },
                        .{
                            // color
                            .shader_location = 1,
                            .offset = particle_color_offset,
                            .format = .float32x4,
                        },
                    },
                }),
                gpu.VertexBufferLayout.init(.{
                    // quad vertex buffer
                    .array_stride = 2 * 4, // vec2<f32>
                    .step_mode = .vertex,
                    .attributes = &.{
                        .{
                            // vertex positions
                            .shader_location = 2,
                            .offset = 0,
                            .format = .float32x2,
                        },
                    },
                }),
            },
        }),
        .fragment = &gpu.FragmentState.init(.{
            .module = frag_module,
            .entry_point = "main",
            .targets = &[_]gpu.ColorTargetState{.{
                .format = app.core.descriptor().format,
                .blend = &gpu.BlendState{
                    .color = .{
                        .src_factor = .src_alpha,
                        .dst_factor = .one,
                        .operation = .add,
                    },
                    .alpha = .{
                        .src_factor = .zero,
                        .dst_factor = .one,
                        .operation = .add,
                    },
                },
            }},
        }),
        .primitive = .{
            .topology = .triangle_list,
        },
        .depth_stencil = &gpu.DepthStencilState{
            .depth_write_enabled = false,
            .depth_compare = .less,
            .format = .depth24_plus,
        },
    });

    const size = app.core.size();
    const depth_texture = app.core.device().createTexture(&gpu.Texture.Descriptor{
        .size = .{ .width = size.width, .height = size.height },
        .format = .depth24_plus,
        .usage = .{ .render_attachment = true },
    });

    const uniform_buffer_size =
        4 * 4 * 4 + // modelViewProjectionMatrix : mat4x4<f32>
        3 * 4 + // right : vec3<f32>
        4 + // padding
        3 * 4 + // up : vec3<f32>
        4 + // padding
        0;
    const uniform_buffer = app.core.device().createBuffer(&.{
        .size = uniform_buffer_size,
        .usage = .{ .uniform = true, .copy_dst = true },
    });

    const uniform_bind_group = app.core.device().createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = render_pipeline.getBindGroupLayout(0),
        .entries = &.{gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, uniform_buffer_size)},
    }));
    _ = uniform_bind_group;

    const render_pass_descriptor = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{
            gpu.RenderPassColorAttachment{
                .view = undefined, // Assigned later
                .clear_value = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
                .load_op = .clear,
                .store_op = .store,
            },
        },
        .depth_stencil_attachment = &.{
            .view = depth_texture.createView(&.{}),
            .depth_clear_value = 1.0,
            .depth_load_op = .clear,
            .depth_store_op = .store,
        },
    });
    _ = render_pass_descriptor;

      const quadVertexBuffer = app.core.device().createBuffer(.{
    .size = 6 * 2 * 4, // 6x vec2<f32>
    .usage = GPUBufferUsage.VERTEX,
    .mappedAtCreation = true,
  });
  // prettier-ignore
  const vertexData = [
    -1.0, -1.0, +1.0, -1.0, -1.0, +1.0, -1.0, +1.0, +1.0, -1.0, +1.0, +1.0,
  ];
  new Float32Array(quadVertexBuffer.getMappedRange()).set(vertexData);
  quadVertexBuffer.unmap();

  //////////////////////////////////////////////////////////////////////////////
  // Texture
  //////////////////////////////////////////////////////////////////////////////
  let .texture = GPUTexture;
  let textureWidth = 1;
  let textureHeight = 1;
  let numMipLevels = 1;
  {
    const img = document.createElement('img');
    img.src = new URL(
      '../../../assets/img/webgpu.png',
      import.meta.url
    ).toString();
    await img.decode();
    const imageBitmap = await createImageBitmap(img);

    // Calculate number of mip levels required to generate the probability map
    while (
      textureWidth < imageBitmap.width ||
      textureHeight < imageBitmap.height
    ) {
      textureWidth *= 2;
      textureHeight *= 2;
      numMipLevels++;
    }
    texture = app.core.device().createTexture({
      .size = [imageBitmap.width, imageBitmap.height, 1],
      .mipLevelCount = numMipLevels,
      .format = 'rgba8unorm',
      .usage =
        GPUTextureUsage.TEXTURE_BINDING |
        GPUTextureUsage.STORAGE_BINDING |
        GPUTextureUsage.COPY_DST |
        GPUTextureUsage.RENDER_ATTACHMENT,
    });
    app.core.device().queue.copyExternalImageToTexture(
      { .source = imageBitmap },
      { .texture = texture },
      [imageBitmap.width, imageBitmap.height]
    );
  }
}

pub fn deinit(app: *App) void {
    app.core.deinit();
    _ = gpa.deinit();
}

pub fn update(app: *App) !bool {
    while (app.core.pollEvents()) |event| {
        switch (event) {
            .close => return true,
            else => {},
        }
    }

    const back_buffer_view = app.core.swapChain().getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = app.core.device().createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.draw(3, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    app.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    app.core.swapChain().present();
    back_buffer_view.release();

    return false;
}
