const std = @import("std");
const builtin = @import("builtin");

const kernel32 = opaque {
    usingnamespace std.os.windows.kernel32;
    extern "kernel32" fn SetConsoleMode(*anyopaque, u32) callconv(std.os.windows.WINAPI) c_int;
};

const UTF8ConsoleOutput = struct {
    original: c_uint = undefined,
    fn init() UTF8ConsoleOutput {
        var self = UTF8ConsoleOutput{};
        if (builtin.os.tag == .windows) {
            //const kernel32 = std.os.windows.kernel32;
            self.original = kernel32.GetConsoleOutputCP();
            _ = kernel32.SetConsoleOutputCP(65001);
        }
        return self;
    }
    fn deinit(self: *UTF8ConsoleOutput) void {
        if (self.original != undefined) {
            _ = std.os.windows.kernel32.SetConsoleOutputCP(self.original);
        }
    }
};

pub const Terminal = struct {
    cp_out: UTF8ConsoleOutput,
    stdout_mode: u32,
    config: std.io.tty.Config,

    const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4;

    pub fn init() Terminal {
        const cp_out = UTF8ConsoleOutput.init();
        var stdout_mode: u32 = undefined;
        _ = kernel32.GetConsoleMode(std.io.getStdOut().handle, &stdout_mode);
        _ = kernel32.SetConsoleMode(std.io.getStdOut().handle, stdout_mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
        return .{ .cp_out = cp_out, .stdout_mode = stdout_mode, .config = .escape_codes };
    }

    pub fn setColor(self: Terminal, color: std.io.tty.Color) void {
        self.config.setColor(std.io.getStdOut().writer(), color);
    }

    pub fn resetColor(self: Terminal) void {
        self.config.setColor(std.io.getStdOut().writer(), .resetColor);
    }

    pub fn deinit(self: *Terminal) void {
        self.cp_out.deinit();
        _ = kernel32.SetConsoleMode(std.io.getStdOut().handle, self.stdout_mode);
    }
};
