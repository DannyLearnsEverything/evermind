const std = @import("std");
const db = @import("db.zig");

pub const TaskStore = struct {
    _db: *db.Db,

    pub fn init(database: *db.Db) TaskStore {
        return .{ ._db = database };
    }

    // TODO: create a task
    //   - generate a UUID for the task id (see uuidV4 helper below)
    //   - wrap in a transaction: exec("BEGIN"), defer exec("ROLLBACK"), exec("COMMIT")
    //     the defer-rollback pattern means: if anything fails before commit, auto-rollback
    //   - append event: INSERT INTO events(type, data) VALUES ('task_created', jsonb(?))
    //     bind the JSON payload as text — jsonb() in the SQL converts it
    //     payload shape: {"id":"<uuid>","title":"<title>"}
    //   - update projection: INSERT INTO tasks(id, title, status) VALUES (?, ?, 'pending')
    //   - return the generated uuid on success
    pub fn createTask(self: *TaskStore, title: []const u8) !void {
        _ = self;
        _ = title;
        return error.NotImplemented;
    }

    // TODO: list all tasks
    //   - prepare: SELECT id, title, status FROM tasks
    //   - step in a loop, collecting results
    //   - caller owns the returned memory — dupe strings with the provided allocator
    //   - think about: what do you need to free if allocation fails mid-loop?
    pub fn listTasks(self: *TaskStore, allocator: std.mem.Allocator) ![]Task {
        _ = self;
        _ = allocator;
        return error.NotImplemented;
    }
};

pub const Task = struct {
    id: []const u8,
    title: []const u8,
    status: []const u8,
};

// test "create and list tasks" {
//     var database = try db.Db.init(":memory:");
//     defer database.deinit();
//     try database.exec(db.schema);
//
//     var store = TaskStore.init(&database);
//     try store.createTask("Buy groceries");
//     try store.createTask("Walk the dog");
//
//     const tasks = try store.listTasks(std.testing.allocator);
//     defer {
//         for (tasks) |task| {
//             std.testing.allocator.free(task.id);
//             std.testing.allocator.free(task.title);
//             std.testing.allocator.free(task.status);
//         }
//         std.testing.allocator.free(tasks);
//     }
//
//     try std.testing.expectEqual(2, tasks.len);
// }
