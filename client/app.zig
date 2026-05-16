const std = @import("std");
const c = @import("c");
const render = @import("render.zig");
const tasks = @import("tasks.zig");

pub const App = struct {
    allocator: std.mem.Allocator,
    tasks: tasks.State,
    running: bool,

    pub fn init(allocator: std.mem.Allocator) App {
        return .{
            .allocator = allocator,
            .tasks = tasks.State.init(allocator),
            .running = true,
        };
    }

    pub fn deinit(self: *App) void {
        self.tasks.deinit();
    }

    pub fn handleEvent(self: *App, e: c.SDL_Event) !void {
        switch (e.type) {
            c.SDL_EVENT_QUIT => self.running = false,
            c.SDL_EVENT_KEY_DOWN => {
                const action: ?tasks.Action = switch (e.key.key) {
                    c.SDLK_ESCAPE => {
                        self.running = false;
                        return;
                    },
                    c.SDLK_RETURN => .submit,
                    c.SDLK_BACKSPACE => .delete_char,
                    c.SDLK_UP => .select_prev,
                    c.SDLK_DOWN => .select_next,
                    c.SDLK_DELETE => .delete_selected,
                    else => null,
                };
                if (action) |a| try self.tasks.apply(a);
            },
            c.SDL_EVENT_TEXT_INPUT => {
                const ch = e.text.text[0];
                if (ch >= ' ') {
                    try self.tasks.apply(.{ .add_char = ch });
                }
            },
            else => {},
        }
    }

    pub fn draw(self: *const App, renderer: *c.SDL_Renderer, text_obj: *c.TTF_Text) void {
        _ = c.SDL_SetRenderDrawColor(renderer, render.BG_COLOR.r, render.BG_COLOR.g, render.BG_COLOR.b, render.BG_COLOR.a);
        _ = c.SDL_RenderClear(renderer);

        self.tasks.draw(renderer, text_obj);

        _ = c.SDL_RenderPresent(renderer);
    }
};
