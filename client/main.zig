const std = @import("std");
const c = @import("c");
const render = @import("render.zig");
const App = @import("app.zig").App;

pub fn main() !void {
    var debug_alloc: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_alloc.deinit();
    const allocator = debug_alloc.allocator();

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.log.err("SDL_Init: {s}", .{c.SDL_GetError()});
        return;
    }
    defer c.SDL_Quit();

    if (!c.TTF_Init()) {
        std.log.err("TTF_Init: {s}", .{c.SDL_GetError()});
        return;
    }
    defer c.TTF_Quit();

    const window = c.SDL_CreateWindow("Evermind", render.WINDOW_W, render.WINDOW_H, 0) orelse {
        std.log.err("CreateWindow: {s}", .{c.SDL_GetError()});
        return;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, null) orelse {
        std.log.err("CreateRenderer: {s}", .{c.SDL_GetError()});
        return;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const font = c.TTF_OpenFont(render.FONT_PATH, render.FONT_SIZE) orelse {
        std.log.err("OpenFont: {s}", .{c.SDL_GetError()});
        return;
    };
    defer c.TTF_CloseFont(font);

    const text_engine = c.TTF_CreateRendererTextEngine(renderer) orelse {
        std.log.err("TextEngine: {s}", .{c.SDL_GetError()});
        return;
    };
    defer c.TTF_DestroyRendererTextEngine(text_engine);

    const text_obj = c.TTF_CreateText(text_engine, font, "", 0) orelse {
        std.log.err("CreateText: {s}", .{c.SDL_GetError()});
        return;
    };
    defer c.TTF_DestroyText(text_obj);

    _ = c.SDL_StartTextInput(window);
    defer _ = c.SDL_StopTextInput(window);

    var app = App.init(allocator);
    defer app.deinit();

    while (app.running) {
        var e: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&e)) {
            app.handleEvent(e) catch |err| {
                std.log.err("handleEvent: {}", .{err});
            };
        }
        app.draw(renderer, text_obj);
    }

    std.log.info("Goodbye", .{});
}
