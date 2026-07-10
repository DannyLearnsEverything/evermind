const std = @import("std");

pub const Task = struct {
    id: u64,
    text: []const u8,
    completed: bool,
};

/// Result type for operations that return a list of tasks.
/// The caller owns the returned slice and its contents.
pub const TaskList = struct {
    items: []Task,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *TaskList) void {
        for (self.items) |item| {
            self.allocator.free(item.text);
        }
        self.allocator.free(self.items);
    }
};

test "Task struct layout" {
    const task = Task{ .id = 1, .text = "test", .completed = false };
    try std.testing.expect(!task.completed);
    try std.testing.expect(std.mem.eql(u8, "test", task.text));
}
