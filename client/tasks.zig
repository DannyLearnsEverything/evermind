const std = @import("std");
const c = @import("c");
const render = @import("render.zig");

pub const Action = union(enum) {
    add_char: u8,
    delete_char,
    submit,
    select_next,
    select_prev,
    delete_selected,
};

pub const State = struct {
    allocator: std.mem.Allocator,
    items: std.ArrayList([]const u8),
    input_buf: std.ArrayList(u8),
    selected_index: usize,

    pub fn init(allocator: std.mem.Allocator) State {
        return .{
            .allocator = allocator,
            .items = .empty,
            .input_buf = .empty,
            .selected_index = 0,
        };
    }

    pub fn deinit(self: *State) void {
        for (self.items.items) |item| {
            self.allocator.free(item);
        }
        self.items.deinit(self.allocator);
        self.input_buf.deinit(self.allocator);
    }

    pub fn apply(self: *State, action: Action) !void {
        switch (action) {
            .add_char => |ch| {
                try self.input_buf.append(self.allocator, ch);
            },
            .delete_char => {
                if (self.input_buf.items.len == 0) return;
                _ = self.input_buf.orderedRemove(self.input_buf.items.len - 1);
            },
            .submit => {
                if (self.input_buf.items.len == 0) return;
                const duped = try self.allocator.dupe(u8, self.input_buf.items);
                errdefer self.allocator.free(duped);
                try self.items.append(self.allocator, duped);
                self.input_buf.clearRetainingCapacity();
            },
            .select_next => {
                self.selected_index = clampIndex(self.selected_index +| 1, self.items.items.len);
            },
            .select_prev => {
                self.selected_index = clampIndex(self.selected_index -| 1, self.items.items.len);
            },
            .delete_selected => {
                if (self.items.items.len > 0) {
                    const removed = self.items.orderedRemove(self.selected_index);
                    self.allocator.free(removed);
                }
                self.selected_index = clampIndex(self.selected_index, self.items.items.len);
            },
        }
    }

    pub fn draw(self: *const State, renderer: *c.SDL_Renderer, text_obj: *c.TTF_Text) void {
        for (self.items.items, 0..) |item, i| {
            const x = render.LEFT_MARGIN;
            const y = render.ITEMS_START_Y + render.LINE_HEIGHT * @as(f32, @floatFromInt(i));

            if (self.selected_index == i) {
                _ = c.TTF_SetTextString(text_obj, item.ptr, item.len);
                var w: c_int = undefined;
                var h: c_int = undefined;
                _ = c.TTF_GetTextSize(text_obj, &w, &h);
                render.fillRect(renderer, render.HIGHLIGHT_COLOR, .{
                    .x = x,
                    .y = y,
                    .w = @as(f32, @floatFromInt(w)),
                    .h = @as(f32, @floatFromInt(h)),
                });
            }

            render.drawText(text_obj, item, render.TEXT_COLOR, x, y);
        }

        // Input area
        if (self.input_buf.items.len > 0) {
            render.drawText(text_obj, self.input_buf.items, render.INPUT_COLOR, render.LEFT_MARGIN, render.INPUT_Y);
        } else {
            render.drawText(text_obj, "Type here...", render.DIM_COLOR, render.LEFT_MARGIN, render.INPUT_Y);
        }

        // Separator
        render.fillRect(renderer, render.SEP_COLOR, .{
            .x = 0,
            .y = render.SEPARATOR_Y,
            .w = @as(f32, @floatFromInt(render.WINDOW_W)),
            .h = 1.0,
        });
    }
};

fn clampIndex(index: usize, len: usize) usize {
    if (len == 0) return 0;
    return @min(index, len - 1);
}
