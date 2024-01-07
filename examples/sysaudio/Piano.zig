// A simple tone engine.
//
// It renders 512 tones simultaneously, each with their own frequency and duration.
//
// `keyToFrequency` can be used to convert a keyboard key to a frequency, so that the
// keys asdfghj on your QWERTY keyboard will map to the notes C/D/E/F/G/A/B[4], the
// keys above qwertyu will map to C5 and the keys below zxcvbnm will map to C3.
//
// The duration is hard-coded to 1.5s. To prevent clicking, tones are faded in linearly over
// the first 1/64th duration of the tone. To provide a cool sustained effect, tones are faded
// out using 1-log10(x*10) (google it to see how it looks, it's strong for most of the duration of
// the note then fades out slowly.)
const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");
const opus = @import("opus");
const Audio = @import("Audio.zig");
const core = mach.core;
const math = mach.math;
const sysaudio = mach.sysaudio;

pub const name = .piano;
pub const Mod = mach.Mod(@This());

music: [4][]const f32,

pub fn init(app: *Mod, audio: *Audio.Mod) !void {
    const space_ambience = try std.fs.cwd().openFile("../../examples/sysaudio/space_ambience_alexander_nakarada.ogx", .{});
    defer space_ambience.close();
    app.state.music[0] = (try opus.decodeStream(core.allocator, .{ .file = space_ambience })).samples;

    const charge_up = try std.fs.cwd().openFile("../../examples/sysaudio/charge_up.ogx", .{});
    defer charge_up.close();
    app.state.music[1] = (try opus.decodeStream(core.allocator, .{ .file = charge_up })).samples;

    try audio.send(.init, .{core.allocator});
    try audio.send(.add, .{app.state.music[0]});
}

pub fn deinit(app: *Mod, audio: *Audio.Mod) !void {
    _ = app;
    try audio.send(.deinit, .{});
}

pub fn tick(app: *Mod, engine: *mach.Engine.Mod, audio: *Audio.Mod) !void {
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| switch (ev.key) {
                .c => try audio.send(.play, .{}),
                .p => try audio.send(.pause, .{}),
                .e => try audio.send(.playSound, .{app.state.music[1]}),
                else => {},
            },
            .close => try engine.send(.exit, .{}),
            else => {},
        }
    }

    try engine.send(.beginPass, .{ mach.gpu.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, null });
    try engine.send(.endPass, .{});
    try engine.send(.present, .{}); // Present the frame

}
