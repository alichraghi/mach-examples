const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");
const Audio = @import("Audio.zig");
const Piano = @import("Piano.zig");
const math = mach.math;
const sysaudio = mach.sysaudio;

pub const modules = .{
    mach.Engine,
    Piano,
    Audio,
};

pub const App = mach.App;
