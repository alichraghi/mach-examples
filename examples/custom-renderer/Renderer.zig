const std = @import("std");
const gpu = @import("mach").gpu;
const ecs = @import("mach").ecs;
const core = @import("mach").core;

const num_bind_groups = 1024 * 32;

// uniform bind group offset must be 256-byte aligned
const uniform_offset = 256;

pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,
bind_groups: [num_bind_groups]*gpu.BindGroup,
uniform_buffer: *gpu.Buffer,

pub const name = .renderer;

pub const components = .{
    .location = Vec3,
    .rotation = Vec3,
    .scale = f32,
};

pub const Vec3 = @Vector(3, f32);

const UniformBufferObject = packed struct {
    offset: Vec3,
    scale: f32,
};

pub fn init(adapter: anytype) !void {
    var mach = adapter.mod(.mach);
    var renderer = adapter.mod(.renderer);
    const device = mach.state().device;

    const shader_module = device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));

    // Fragment state
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    const uniform_buffer = device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject) * uniform_offset * num_bind_groups,
        .mapped_at_creation = false,
    });
    const bind_group_layout_entry = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bind_group_layout = device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{bind_group_layout_entry},
        }),
    );
    var bind_groups: [num_bind_groups]*gpu.BindGroup = undefined;
    for (bind_groups, 0..) |_, i| {
        bind_groups[i] = device.createBindGroup(
            &gpu.BindGroup.Descriptor.init(.{
                .layout = bind_group_layout,
                .entries = &.{
                    gpu.BindGroup.Entry.buffer(0, uniform_buffer, uniform_offset * i, @sizeOf(UniformBufferObject)),
                },
            }),
        );
    }

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };

    renderer.initState(.{
        .pipeline = device.createRenderPipeline(&pipeline_descriptor),
        .queue = device.getQueue(),
        .bind_groups = bind_groups,
        .uniform_buffer = uniform_buffer,
    });
    shader_module.release();
}

pub fn deinit(adapter: anytype) !void {
    var renderer = adapter.mod(.renderer);

    renderer.state().pipeline.release();
    renderer.state().queue.release();
    for (renderer.state().bind_groups) |bind_group| bind_group.release();
    renderer.state().uniform_buffer.release();
}

pub fn tick(adapter: anytype) !void {
    var mach = adapter.mod(.mach);
    var renderer = adapter.mod(.renderer);
    const device = mach.state().device;

    // Begin our render pass
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });

    // Update uniform buffer
    var archetypes_iter = adapter.entities.query(.{ .all = &.{
        .{ .renderer = &.{ .location, .scale } },
    } });
    var num_entities: usize = 0;
    while (archetypes_iter.next()) |archetype| {
        var ids = archetype.slice(.entity, .id);
        var locations = archetype.slice(.renderer, .location);
        var scales = archetype.slice(.renderer, .scale);
        for (ids, locations, scales) |id, location, scale| {
            _ = id;

            const ubo = UniformBufferObject{
                .offset = location,
                .scale = scale,
            };
            encoder.writeBuffer(renderer.state().uniform_buffer, uniform_offset * num_entities, &[_]UniformBufferObject{ubo});
            num_entities += 1;
        }
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    for (renderer.state().bind_groups[0..num_entities]) |bind_group| {
        pass.setPipeline(renderer.state().pipeline);
        pass.setBindGroup(0, bind_group, &.{0});
        pass.draw(3, 1, 0, 0);
    }
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    renderer.state().queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swap_chain.present();
    back_buffer_view.release();
}
