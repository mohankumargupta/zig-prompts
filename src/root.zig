const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;
const ansi = @import("ansi.zig");
const getch = @cImport({
    @cInclude("getch.h");
});
const terminal = @import("terminal_windows.zig");
const Terminal = terminal.Terminal;

// #ifdef _WIN32
// 	static int const keyDw = 80;
// 	static int const keyUp = 72;
// 	static int const keySx = 75;
// 	static int const keyDx = 77;
// 	static int const keyEnter = 13;
// #else
// 	static int const keyUp = 65;
// 	static int const keyDw = 66;
// 	static int const keySx = 68;
// 	static int const keyDx = 67;
// 	static int const keyEnter = 13;
// #endif

const Keyboard = enum(u8) {
    DOWN = 80,
    UP = 72,
    RIGHT = 77,
    LEFT = 75,
    ENTER = 13,
};

const Figures = struct {
    arrowUp: []const u8,
    arrowDown: []const u8,
    arrowLeft: []const u8,
    arrowRight: []const u8,
    radioOn: []const u8,
    radioOff: []const u8,
    tick: []const u8,
    cross: []const u8,
    ellipsis: []const u8,
    pointerSmall: []const u8,
    line: []const u8,
    pointer: []const u8,

    fn windows() Figures {
        return .{
            .arrowUp = "↑",
            .arrowDown = "↓",
            .arrowLeft = "←",
            .arrowRight = "→",
            .radioOn = "(*)",
            .radioOff = "( )",
            .tick = "√",
            .cross = "×",
            .ellipsis = "...",
            .pointerSmall = "»",
            .line = "─",
            .pointer = ">",
        };
    }

    fn other() Figures {
        return .{ .arrowUp = "↑", .arrowDown = "↓", .arrowLeft = "←", .arrowRight = "→", .radioOn = "◉", .radioOff = "◯", .tick = "✔", .cross = "✖", .ellipsis = "…", .pointerSmall = "›", .line = "─", .pointer = "❯" };
    }

    pub fn getFigures() Figures {
        const os = builtin.os;
        const figures = if (os.tag == .windows) windows() else other();
        return figures;
    }
};

pub const Inquirer = struct {
    terminal: Terminal = undefined,
    pub const QuestionType = enum { SELECT };

    pub fn init() Inquirer {
        const term = Terminal.init();
        return .{ .terminal = term };
    }

    pub fn deinit(self: *const Inquirer) void {
        _ = self;
    }

    fn println(out: anytype) !void {
        try out.print("\n", .{});
    }

    fn printSelectionQuestion(out: anytype, comptime prompt: []const u8, answered: bool) !void {
        if (!answered) {
            try out.print(comptime ansi.color.Fg(.Blue, "? "), .{});
        } else {
            try out.print(comptime ansi.color.Fg(.Green, Figures.getFigures().tick), .{});
            try out.print(comptime ansi.color.Fg(.Blue, " "), .{});
        }

        try out.print(comptime ansi.color.Bold(ansi.color.Fg(.White, prompt)), .{});
    }

    fn printSelectOptions(out: anytype, options: []const []const u8, selectedIndex: usize) !void {
        //try out.print("\n", .{});

        for (options, 0..) |option, i| {
            if (i == selectedIndex) {
                try out.print(comptime ansi.color.Fg(.Blue, "> {s}\n"), .{option});
            } else {
                try out.print("  {s}\n", .{option});
            }
        }
    }

    fn clearLines(out: anytype, count: usize) !void {
        for (0..count) |_| {
            try out.print("{s}", .{ansi.csi.CursorUp(1)});
            try out.print("{s}", .{ansi.csi.EraseInLine(2)});
        }
    }

    pub fn select(self: Inquirer, out: anytype, in: anytype, comptime prompt: []const u8, comptime options: []const []const u8) !void {
        _ = self;
        var selectedIndex: usize = 0;
        _ = in;

        try printSelectionQuestion(out, prompt, true);
        try println(out);

        while (true) {
            try printSelectOptions(out, options, selectedIndex);
            const keyPressed = getch.getch();
            const optionslen: usize = options.len;
            if (keyPressed == @intFromEnum(Keyboard.DOWN)) {
                selectedIndex = (selectedIndex + 1) % optionslen;
                try clearLines(out, optionslen);
            } else if (keyPressed == @intFromEnum(Keyboard.UP)) {
                if (selectedIndex == 0) {
                    selectedIndex = optionslen - 1;
                } else {
                    selectedIndex = selectedIndex - 1;
                }
                try clearLines(out, optionslen);
            } else if (keyPressed == @intFromEnum(Keyboard.ENTER)) {
                break;
            }
        }
    }
};

test "basic add functionality" {}
