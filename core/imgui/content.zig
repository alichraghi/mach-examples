const mach = @import("mach");
const imgui = @import("imgui.zig");

pub fn renderContent() void {
    imgui.mach_backend.newFrame();

    if (!imgui.begin("Demo Settings", .{})) {
        imgui.end();
        return;
    }

    if (imgui.collapsingHeader("Widgets: Main", .{})) {
        imgui.textUnformattedColored(.{ 0, 0.8, 0, 1 }, "Button");
        if (imgui.button("Button 1", .{ .w = 200.0 })) {
            // 'Button 1' pressed.
        }
        imgui.sameLine(.{ .spacing = 20.0 });
        if (imgui.button("Button 2", .{ .h = 60.0 })) {
            // 'Button 2' pressed.
        }
        imgui.sameLine(.{});
        {
            const label = "Button 3 is special ;)";
            const s = imgui.calcTextSize(label, .{});
            _ = imgui.button(label, .{ .w = s[0] + 30.0 });
        }
        imgui.sameLine(.{});
        _ = imgui.button("Button 4", .{});
        _ = imgui.button("Button 5", .{ .w = -1.0, .h = 100.0 });

        imgui.pushStyleColor4f(.{ .idx = .text, .c = .{ 1.0, 0.0, 0.0, 1.0 } });
        _ = imgui.button("  Red Text Button  ", .{});
        imgui.popStyleColor(.{});

        imgui.sameLine(.{});
        imgui.pushStyleColor4f(.{ .idx = .text, .c = .{ 1.0, 1.0, 0.0, 1.0 } });
        _ = imgui.button("  Yellow Text Button  ", .{});
        imgui.popStyleColor(.{});

        _ = imgui.smallButton("  Small Button  ");
        imgui.sameLine(.{});
        _ = imgui.arrowButton("left_button_id", .{ .dir = .left });
        imgui.sameLine(.{});
        _ = imgui.arrowButton("right_button_id", .{ .dir = .right });
        imgui.spacing();

        const static = struct {
            var check0: bool = true;
            var bits: u32 = 0xf;
            var radio_value: u32 = 1;
            var month: i32 = 1;
            var progress: f32 = 0.0;
        };
        imgui.textUnformattedColored(.{ 0, 0.8, 0, 1 }, "Checkbox");
        _ = imgui.checkbox("Magic Is Everywhere", .{ .v = &static.check0 });
        imgui.spacing();

        imgui.textUnformattedColored(.{ 0, 0.8, 0, 1 }, "Checkbox bits");
        imgui.text("Bits value: {b} ({d})", .{ static.bits, static.bits });
        _ = imgui.checkboxBits("Bit 0", .{ .bits = &static.bits, .bits_value = 0x1 });
        _ = imgui.checkboxBits("Bit 1", .{ .bits = &static.bits, .bits_value = 0x2 });
        _ = imgui.checkboxBits("Bit 2", .{ .bits = &static.bits, .bits_value = 0x4 });
        _ = imgui.checkboxBits("Bit 3", .{ .bits = &static.bits, .bits_value = 0x8 });
        imgui.spacing();

        imgui.textUnformattedColored(.{ 0, 0.8, 0, 1 }, "Radio buttons");
        if (imgui.radioButton("One", .{ .active = static.radio_value == 1 })) static.radio_value = 1;
        if (imgui.radioButton("Two", .{ .active = static.radio_value == 2 })) static.radio_value = 2;
        if (imgui.radioButton("Three", .{ .active = static.radio_value == 3 })) static.radio_value = 3;
        if (imgui.radioButton("Four", .{ .active = static.radio_value == 4 })) static.radio_value = 4;
        if (imgui.radioButton("Five", .{ .active = static.radio_value == 5 })) static.radio_value = 5;
        imgui.spacing();

        _ = imgui.radioButtonStatePtr("January", .{ .v = &static.month, .v_button = 1 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("February", .{ .v = &static.month, .v_button = 2 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("March", .{ .v = &static.month, .v_button = 3 });
        imgui.spacing();

        imgui.textUnformattedColored(.{ 0, 0.8, 0, 1 }, "Progress bar");
        imgui.progressBar(.{ .fraction = static.progress });
        static.progress += 0.005;
        if (static.progress > 1.0) static.progress = 0.0;
        imgui.spacing();

        imgui.bulletText("keep going...", .{});
    }

    if (imgui.collapsingHeader("Widgets: Combo Box", .{})) {
        const static = struct {
            var selection_index: u32 = 0;
            var current_item: i32 = 0;
        };

        const items = [_][:0]const u8{ "aaa", "bbb", "ccc", "ddd", "eee", "FFF", "ggg", "hhh" };
        if (imgui.beginCombo("Combo 0", .{ .preview_value = items[static.selection_index] })) {
            for (items, 0..) |item, index| {
                const i = @as(u32, @intCast(index));
                if (imgui.selectable(item, .{ .selected = static.selection_index == i }))
                    static.selection_index = i;
            }
            imgui.endCombo();
        }

        _ = imgui.combo("Combo 1", .{
            .current_item = &static.current_item,
            .items_separated_by_zeros = "Item 0\x00Item 1\x00Item 2\x00Item 3\x00\x00",
        });
    }

    if (imgui.collapsingHeader("Widgets: Drag Sliders", .{})) {
        const static = struct {
            var v1: f32 = 0.0;
            var v2: [2]f32 = .{ 0.0, 0.0 };
            var v3: [3]f32 = .{ 0.0, 0.0, 0.0 };
            var v4: [4]f32 = .{ 0.0, 0.0, 0.0, 0.0 };
            var range: [2]f32 = .{ 0.0, 0.0 };
            var v1i: i32 = 0.0;
            var v2i: [2]i32 = .{ 0, 0 };
            var v3i: [3]i32 = .{ 0, 0, 0 };
            var v4i: [4]i32 = .{ 0, 0, 0, 0 };
            var rangei: [2]i32 = .{ 0, 0 };
            var si8: i8 = 123;
            var vu16: [3]u16 = .{ 10, 11, 12 };
            var sd: f64 = 0.0;
        };
        _ = imgui.dragFloat("Drag float 1", .{ .v = &static.v1 });
        _ = imgui.dragFloat2("Drag float 2", .{ .v = &static.v2 });
        _ = imgui.dragFloat3("Drag float 3", .{ .v = &static.v3 });
        _ = imgui.dragFloat4("Drag float 4", .{ .v = &static.v4 });
        _ = imgui.dragFloatRange2(
            "Drag float range 2",
            .{ .current_min = &static.range[0], .current_max = &static.range[1] },
        );
        _ = imgui.dragInt("Drag int 1", .{ .v = &static.v1i });
        _ = imgui.dragInt2("Drag int 2", .{ .v = &static.v2i });
        _ = imgui.dragInt3("Drag int 3", .{ .v = &static.v3i });
        _ = imgui.dragInt4("Drag int 4", .{ .v = &static.v4i });
        _ = imgui.dragIntRange2(
            "Drag int range 2",
            .{ .current_min = &static.rangei[0], .current_max = &static.rangei[1] },
        );
        _ = imgui.dragScalar("Drag scalar (i8)", i8, .{ .v = &static.si8, .min = -20 });
        _ = imgui.dragScalarN(
            "Drag scalar N ([3]u16)",
            @TypeOf(static.vu16),
            .{ .v = &static.vu16, .max = 100 },
        );
        _ = imgui.dragScalar(
            "Drag scalar (f64)",
            f64,
            .{ .v = &static.sd, .min = -1.0, .max = 1.0, .speed = 0.005 },
        );
    }

    if (imgui.collapsingHeader("Widgets: Regular Sliders", .{})) {
        const static = struct {
            var v1: f32 = 0;
            var v2: [2]f32 = .{ 0, 0 };
            var v3: [3]f32 = .{ 0, 0, 0 };
            var v4: [4]f32 = .{ 0, 0, 0, 0 };
            var v1i: i32 = 0;
            var v2i: [2]i32 = .{ 0, 0 };
            var v3i: [3]i32 = .{ 10, 10, 10 };
            var v4i: [4]i32 = .{ 0, 0, 0, 0 };
            var su8: u8 = 1;
            var vu16: [3]u16 = .{ 10, 11, 12 };
            var vsf: f32 = 0;
            var vsi: i32 = 0;
            var vsu8: u8 = 1;
            var angle: f32 = 0;
        };
        _ = imgui.sliderFloat("Slider float 1", .{ .v = &static.v1, .min = 0.0, .max = 1.0 });
        _ = imgui.sliderFloat2("Slider float 2", .{ .v = &static.v2, .min = -1.0, .max = 1.0 });
        _ = imgui.sliderFloat3("Slider float 3", .{ .v = &static.v3, .min = 0.0, .max = 1.0 });
        _ = imgui.sliderFloat4("Slider float 4", .{ .v = &static.v4, .min = 0.0, .max = 1.0 });
        _ = imgui.sliderInt("Slider int 1", .{ .v = &static.v1i, .min = 0, .max = 100 });
        _ = imgui.sliderInt2("Slider int 2", .{ .v = &static.v2i, .min = -20, .max = 20 });
        _ = imgui.sliderInt3("Slider int 3", .{ .v = &static.v3i, .min = 10, .max = 50 });
        _ = imgui.sliderInt4("Slider int 4", .{ .v = &static.v4i, .min = 0, .max = 10 });
        _ = imgui.sliderScalar(
            "Slider scalar (u8)",
            u8,
            .{ .v = &static.su8, .min = 0, .max = 100, .cfmt = "%Xh" },
        );
        _ = imgui.sliderScalarN(
            "Slider scalar N ([3]u16)",
            [3]u16,
            .{ .v = &static.vu16, .min = 1, .max = 100 },
        );
        _ = imgui.sliderAngle("Slider angle", .{ .vrad = &static.angle });
        _ = imgui.vsliderFloat(
            "VSlider float",
            .{ .w = 80.0, .h = 200.0, .v = &static.vsf, .min = 0.0, .max = 1.0 },
        );
        imgui.sameLine(.{});
        _ = imgui.vsliderInt(
            "VSlider int",
            .{ .w = 80.0, .h = 200.0, .v = &static.vsi, .min = 0, .max = 100 },
        );
        imgui.sameLine(.{});
        _ = imgui.vsliderScalar(
            "VSlider scalar (u8)",
            u8,
            .{ .w = 80.0, .h = 200.0, .v = &static.vsu8, .min = 0, .max = 200 },
        );
    }

    if (imgui.collapsingHeader("Widgets: Input with Keyboard", .{})) {
        const static = struct {
            var buf: [128]u8 = undefined;
            var buf1: [128]u8 = undefined;
            var buf2: [128]u8 = undefined;
            var v1: f32 = 0;
            var v2: [2]f32 = .{ 0, 0 };
            var v3: [3]f32 = .{ 0, 0, 0 };
            var v4: [4]f32 = .{ 0, 0, 0, 0 };
            var v1i: i32 = 0;
            var v2i: [2]i32 = .{ 0, 0 };
            var v3i: [3]i32 = .{ 0, 0, 0 };
            var v4i: [4]i32 = .{ 0, 0, 0, 0 };
            var sf64: f64 = 0.0;
            var si8: i8 = 0;
            var v3u8: [3]u8 = .{ 0, 0, 0 };
        };
        _ = imgui.inputText("Input text", .{ .buf = static.buf[0..] });
        _ = imgui.inputTextMultiline("Input text multiline", .{ .buf = static.buf1[0..] });
        _ = imgui.inputTextWithHint("Input text with hint", .{ .hint = "Enter your name", .buf = static.buf2[0..] });
        _ = imgui.inputFloat("Input float 1", .{ .v = &static.v1 });
        _ = imgui.inputFloat2("Input float 2", .{ .v = &static.v2 });
        _ = imgui.inputFloat3("Input float 3", .{ .v = &static.v3 });
        _ = imgui.inputFloat4("Input float 4", .{ .v = &static.v4 });
        _ = imgui.inputInt("Input int 1", .{ .v = &static.v1i });
        _ = imgui.inputInt2("Input int 2", .{ .v = &static.v2i });
        _ = imgui.inputInt3("Input int 3", .{ .v = &static.v3i });
        _ = imgui.inputInt4("Input int 4", .{ .v = &static.v4i });
        _ = imgui.inputDouble("Input double", .{ .v = &static.sf64 });
        _ = imgui.inputScalar("Input scalar (i8)", i8, .{ .v = &static.si8 });
        _ = imgui.inputScalarN("Input scalar N ([3]u8)", [3]u8, .{ .v = &static.v3u8 });
    }

    if (imgui.collapsingHeader("Widgets: Color Editor/Picker", .{})) {
        const static = struct {
            var col3: [3]f32 = .{ 0, 0, 0 };
            var col4: [4]f32 = .{ 0, 0, 0, 0 };
            var col3p: [3]f32 = .{ 0, 0, 0 };
            var col4p: [4]f32 = .{ 0, 0, 0, 0 };
        };
        _ = imgui.colorEdit3("Color edit 3", .{ .col = &static.col3 });
        _ = imgui.colorEdit4("Color edit 4", .{ .col = &static.col4 });
        _ = imgui.colorPicker3("Color picker 3", .{ .col = &static.col3p });
        _ = imgui.colorPicker4("Color picker 4", .{ .col = &static.col4p });
        _ = imgui.colorButton("color_button_id", .{ .col = .{ 0, 1, 0, 1 } });
    }

    if (imgui.collapsingHeader("Widgets: Trees", .{})) {
        if (imgui.treeNodeStrId("tree_id", "My Tree {d}", .{1})) {
            imgui.textUnformatted("Some content...");
            imgui.treePop();
        }
        if (imgui.collapsingHeader("Collapsing header 1", .{})) {
            imgui.textUnformatted("Some content...");
        }
    }

    if (imgui.collapsingHeader("Widgets: List Boxes", .{})) {
        const static = struct {
            var selection_index: u32 = 0;
        };
        const items = [_][:0]const u8{ "aaa", "bbb", "ccc", "ddd", "eee", "FFF", "ggg", "hhh" };
        if (imgui.beginListBox("List Box 0", .{})) {
            for (items, 0..) |item, index| {
                const i = @as(u32, @intCast(index));
                if (imgui.selectable(item, .{ .selected = static.selection_index == i }))
                    static.selection_index = i;
            }
            imgui.endListBox();
        }
    }

    const draw_list = imgui.getWindowDrawList();
    draw_list.pushClipRect(.{ .pmin = .{ 0, 0 }, .pmax = .{ 400, 400 } });
    draw_list.addLine(.{ .p1 = .{ 0, 0 }, .p2 = .{ 400, 400 }, .col = 0xff_ff_00_ff, .thickness = 5.0 });
    draw_list.popClipRect();

    draw_list.pushClipRectFullScreen();
    draw_list.addRectFilled(.{
        .pmin = .{ 100, 100 },
        .pmax = .{ 300, 200 },
        .col = 0xff_ff_ff_ff,
        .rounding = 25.0,
    });
    draw_list.addRectFilledMultiColor(.{
        .pmin = .{ 100, 300 },
        .pmax = .{ 200, 400 },
        .col_upr_left = 0xff_00_00_ff,
        .col_upr_right = 0xff_00_ff_00,
        .col_bot_right = 0xff_ff_00_00,
        .col_bot_left = 0xff_00_ff_ff,
    });
    draw_list.addQuadFilled(.{
        .p1 = .{ 150, 400 },
        .p2 = .{ 250, 400 },
        .p3 = .{ 200, 500 },
        .p4 = .{ 100, 500 },
        .col = 0xff_ff_ff_ff,
    });
    draw_list.addQuad(.{
        .p1 = .{ 170, 420 },
        .p2 = .{ 270, 420 },
        .p3 = .{ 220, 520 },
        .p4 = .{ 120, 520 },
        .col = 0xff_00_00_ff,
        .thickness = 3.0,
    });
    draw_list.addText(.{ 130, 130 }, 0xff_00_00_ff, "The number is: {}", .{7});
    draw_list.addCircleFilled(.{ .p = .{ 200, 600 }, .r = 50, .col = 0xff_ff_ff_ff });
    draw_list.addCircle(.{ .p = .{ 200, 600 }, .r = 30, .col = 0xff_00_00_ff, .thickness = 11 });
    draw_list.addPolyline(
        &.{ .{ 100, 700 }, .{ 200, 600 }, .{ 300, 700 }, .{ 400, 600 } },
        .{ .col = 0xff_00_aa_11, .thickness = 7 },
    );
    _ = draw_list.getClipRectMin();
    _ = draw_list.getClipRectMax();
    draw_list.popClipRect();

    imgui.end();
}
