const c = @import("c");

pub const WINDOW_W: c_int = 640;
pub const WINDOW_H: c_int = 480;
pub const FONT_PATH: [*c]const u8 = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
pub const FONT_SIZE: f32 = 20.0;
pub const LINE_HEIGHT: f32 = 28.0;
pub const LEFT_MARGIN: f32 = 20.0;
pub const ITEMS_START_Y: f32 = 20.0;
pub const SEPARATOR_Y: f32 = @as(f32, @floatFromInt(WINDOW_H)) - 60.0;
pub const INPUT_Y: f32 = @as(f32, @floatFromInt(WINDOW_H)) - 40.0;

pub const BG_COLOR: c.SDL_Color = .{ .r = 30, .g = 30, .b = 30, .a = 255 };
pub const TEXT_COLOR: c.SDL_Color = .{ .r = 220, .g = 220, .b = 220, .a = 255 };
pub const HIGHLIGHT_COLOR: c.SDL_Color = .{ .r = 60, .g = 80, .b = 120, .a = 255 };
pub const INPUT_COLOR: c.SDL_Color = .{ .r = 180, .g = 200, .b = 255, .a = 255 };
pub const DIM_COLOR: c.SDL_Color = .{ .r = 100, .g = 100, .b = 100, .a = 255 };
pub const SEP_COLOR: c.SDL_Color = .{ .r = 80, .g = 80, .b = 80, .a = 255 };

/// Draw a filled rect with the given color.
pub fn fillRect(renderer: *c.SDL_Renderer, color: c.SDL_Color, rect: c.SDL_FRect) void {
    _ = c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
    _ = c.SDL_RenderFillRect(renderer, &rect);
}

/// Set text content and color, then draw at (x, y).
pub fn drawText(text_obj: *c.TTF_Text, text: []const u8, color: c.SDL_Color, x: f32, y: f32) void {
    _ = c.TTF_SetTextString(text_obj, text.ptr, text.len);
    _ = c.TTF_SetTextColor(text_obj, color.r, color.g, color.b, color.a);
    _ = c.TTF_DrawRendererText(text_obj, x, y);
}
