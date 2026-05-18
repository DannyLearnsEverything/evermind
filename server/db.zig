const std = @import("std");
const c = @import("c");

const DbError = error{
    OpenFailed,
    ExecFailed,
};

pub const Db = struct {
    handle: *c.sqlite3,

    pub fn init(path: [*:0]const u8) !Db {
        var maybe_handle: ?*c.sqlite3 = undefined;
        if (c.SQLITE_OK != c.sqlite3_open(path, &maybe_handle)) {
            const cause = c.sqlite3_errmsg(maybe_handle);
            std.log.err("Db.init() failed to open connection because {s}", .{cause});
            if (c.SQLITE_OK != c.sqlite3_close(maybe_handle)) {
                std.log.warn("Db.init() received non-ok return code from sqlite3_close()", .{});
            }
            return DbError.OpenFailed;
        }

        if (maybe_handle == null) {
            std.log.err("Db.init() failed to open connection -- sqlite was unable to allocate memory to hold struct", .{});
            return DbError.OpenFailed;
        }

        return .{ .handle = maybe_handle.? };
    }

    pub fn deinit(self: *Db) void {
        const resultCode = c.sqlite3_close(self.handle);
        if (c.SQLITE_OK != resultCode) {
            std.log.warn("DB.deinit() received non-ok return code {d} from sqlite3_close", .{resultCode});
        }
    }

    pub fn exec(self: *Db, sql: [*:0]const u8) !void {
        var cause: [*c]u8 = null;
        const resultCode = c.sqlite3_exec(self.handle, sql, null, null, &cause);
        if (c.SQLITE_OK != resultCode) {
            if (cause != null) {
                std.log.err("DB.exec() failed because {s}", .{cause});
            }
            c.sqlite3_free(cause);
            return DbError.ExecFailed;
        }
    }
};

pub const schema =
    \\ CREATE TABLE IF NOT EXISTS events(
    \\     id      INTEGER PRIMARY KEY AUTOINCREMENT,
    \\     created INTEGER NOT NULL DEFAULT (unixepoch('subsecond')),
    \\     type    TEXT    NOT NULL,
    \\     data    BLOB    NOT NULL CHECK (json_valid(data, 8)), -- JSONB
    \\     version INTEGER NOT NULL DEFAULT 1
    \\ );
    \\ CREATE TABLE IF NOT EXISTS tasks(
    \\     id      TEXT    NOT NULL,
    \\     created INTEGER NOT NULL DEFAULT (unixepoch('subsecond')),
    \\     title   TEXT    NOT NULL,
    \\     status  TEXT    NOT NULL CHECK (status IN ('pending', 'done', 'skipped'))
    \\ )
;

test "open, create schema, close" {
    var db = try Db.init(":memory:");
    defer db.deinit();
    try db.exec(schema);
}
