const std = @import("std");
const Rect = @This();

x: f32,
y: f32,
w: f32,
h: f32,

const Split = struct {
    rect: Rect,
    rest: Rect,
    fn swap(self: Split) Split {
        return .{
            .rect = self.rest,
            .rest = self.rect,
        };
    }
};

fn transpose(self: Rect) Rect {
    return .{
        .x = self.y,
        .y = self.x,
        .w = self.h,
        .h = self.w,
    };
}

fn top(self: Rect, px: f32) Split {
    std.debug.assert(px > 0);
    std.debug.assert(px < self.h);

    const rect: Rect = .{
        .h = px,

        // Unchanged
        .x = self.x,
        .y = self.y,
        .w = self.w,
    };

    const rest: Rect = .{
        .y = self.y + px,
        .h = self.h - px,

        // Unchanged
        .x = self.x,
        .w = self.w,
    };

    return .{
        .rect = rect,
        .rest = rest,
    };
}

fn bottom(self: Rect, px: f32) Split {
    return self.top(self.h - px).swap();
}

fn left(self: Rect, px: f32) Split {
    const split = self.transpose().top(px);
    return .{
        .rect = split.rect.transpose(),
        .rest = split.rest.transpose(),
    };
}

fn right(self: Rect, px: f32) Split {
    return self.left(self.w - px).swap();
}

fn inset(self: Rect, px: f32) Rect {
    return .{
        .x = self.x + px,
        .y = self.y + px,
        .w = self.w - 2 * px,
        .h = self.h - 2 * px,
    };
}

test "inset shrinks uniformly" {
    const r = Rect{ .x = 0, .y = 0, .w = 100, .h = 80 };
    const i = r.inset(10);
    try std.testing.expectEqual(@as(f32, 10), i.x);
    try std.testing.expectEqual(@as(f32, 10), i.y);
    try std.testing.expectEqual(@as(f32, 80), i.w);
    try std.testing.expectEqual(@as(f32, 60), i.h);
}

test "top returns rect and rest" {
    const r = Rect{ .x = 0, .y = 0, .w = 200, .h = 100 };
    const result = r.top(30);
    // rect is the top 30px
    try std.testing.expectEqual(@as(f32, 0), result.rect.y);
    try std.testing.expectEqual(@as(f32, 30), result.rect.h);
    // rest is what's left
    try std.testing.expectEqual(@as(f32, 30), result.rest.y);
    try std.testing.expectEqual(@as(f32, 70), result.rest.h);
    // both preserve x and w
    try std.testing.expectEqual(@as(f32, 200), result.rect.w);
    try std.testing.expectEqual(@as(f32, 200), result.rest.w);
}

test "bottom returns rect and rest" {
    const r = Rect{ .x = 10, .y = 20, .w = 200, .h = 100 };
    const result = r.bottom(25);
    try std.testing.expectEqual(@as(f32, 95), result.rect.y);
    try std.testing.expectEqual(@as(f32, 25), result.rect.h);
    try std.testing.expectEqual(@as(f32, 20), result.rest.y);
    try std.testing.expectEqual(@as(f32, 75), result.rest.h);
}

test "left returns rect and rest" {
    const r = Rect{ .x = 0, .y = 0, .w = 300, .h = 100 };
    const result = r.left(80);
    try std.testing.expectEqual(@as(f32, 0), result.rect.x);
    try std.testing.expectEqual(@as(f32, 80), result.rect.w);
    try std.testing.expectEqual(@as(f32, 80), result.rest.x);
    try std.testing.expectEqual(@as(f32, 220), result.rest.w);
}

test "right returns rect and rest" {
    const r = Rect{ .x = 50, .y = 0, .w = 300, .h = 100 };
    const result = r.right(100);
    try std.testing.expectEqual(@as(f32, 250), result.rect.x);
    try std.testing.expectEqual(@as(f32, 100), result.rect.w);
    try std.testing.expectEqual(@as(f32, 50), result.rest.x);
    try std.testing.expectEqual(@as(f32, 200), result.rest.w);
}

test "inset then top chains cleanly" {
    const r = Rect{ .x = 0, .y = 0, .w = 400, .h = 300 };
    const header = r.inset(8).top(40).rect;
    try std.testing.expectEqual(@as(f32, 8), header.x);
    try std.testing.expectEqual(@as(f32, 8), header.y);
    try std.testing.expectEqual(@as(f32, 384), header.w);
    try std.testing.expectEqual(@as(f32, 40), header.h);
}
