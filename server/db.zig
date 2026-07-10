const std = @import("std");
const c = @import("c");

const DbError = error{
    OpenFailed,
    ExecFailed,
    StmtPrepareFailed,
    StmtBindFailed,
    StmtStepFailed,
};

pub const Db = struct {
    _db: *c.sqlite3,

    pub fn init(path: [*:0]const u8) !Db {
        var maybe_db: ?*c.sqlite3 = undefined;
        if (c.SQLITE_OK != c.sqlite3_open(path, &maybe_db)) {
            const cause = c.sqlite3_errmsg(maybe_db);
            std.log.err("Db.init() failed to open connection because {s}", .{cause});
            if (c.SQLITE_OK != c.sqlite3_close(maybe_db)) {
                std.log.warn("Db.init() received non-ok return code from sqlite3_close()", .{});
            }
            return DbError.OpenFailed;
        }

        if (maybe_db == null) {
            std.log.err("Db.init() failed to open connection -- sqlite was unable to allocate memory to hold struct", .{});
            return DbError.OpenFailed;
        }

        return .{ ._db = maybe_db.? };
    }

    pub fn deinit(self: *Db) void {
        if (c.SQLITE_OK != c.sqlite3_close(self._db)) {
            const cause = c.sqlite3_errmsg(self._db);
            std.log.warn("sqlite3_close failed because {s}", .{cause});
        }
    }

    pub fn exec(self: *Db, sql: [*:0]const u8) !void {
        var cause: [*c]u8 = null;
        const resultCode = c.sqlite3_exec(self._db, sql, null, null, &cause);
        if (c.SQLITE_OK != resultCode) {
            if (cause != null) {
                std.log.err("sqlite3_exec failed because {s}", .{cause});
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

pub const Statement = struct {
    _db: *Db,
    _stmt: *c.sqlite3_stmt,

    pub fn init(db: *Db, sql: [*:0]const u8) !Statement {
        const bytes = -1; // Let sqlite mesaure the string
        const remaining_uncompiled_sql = null; // Ignore extra statements

        var maybe_stmt: ?*c.sqlite3_stmt = undefined;
        if (c.SQLITE_OK != c.sqlite3_prepare_v2(db._db, sql, bytes, &maybe_stmt, remaining_uncompiled_sql)) {
            const cause = c.sqlite3_errmsg(db._db);
            std.log.err("sqlite3_prepare_v2 failed because {s}", .{cause});
            return error.StmtPrepareFailed;
        }

        if (maybe_stmt == null) {
            std.log.err("sqlite3_prepare_v2 failed to compile statement", .{});
            return error.StmtPrepareFailed;
        }

        return .{
            ._db = db,
            ._stmt = maybe_stmt.?,
        };
    }

    pub fn deinit(self: *Statement) void {
        if (c.SQLITE_OK != c.sqlite3_finalize(self._stmt)) {
            const cause = c.sqlite3_errmsg(self._db._db);
            std.log.err("sqlite3_finalize failed because {s}", .{cause});
        }
    }

    pub fn bindText(self: *Statement, index: u16, value: []const u8) !void {
        if (value.len > std.math.maxInt(c_int)) return error.StmtBindFailed;

        if (c.SQLITE_OK != c.sqlite3_bind_text(
            self._stmt,
            index,
            value.ptr,
            @intCast(value.len),
            c.SQLITE_STATIC,
        )) {
            const cause = c.sqlite3_errmsg(self._db._db);
            std.log.err("sqlite3_bind_text failed because {s}", .{cause});
            return error.StmtBindFailed;
        }
    }

    pub fn bindBlob(self: *Statement, index: u16, value: []const u8) !void {
        if (value.len > std.math.maxInt(c_int)) return error.StmtBindFailed;

        if (c.SQLITE_OK != c.sqlite3_bind_blob(
            self._stmt,
            index,
            value.ptr,
            @intCast(value.len),
            c.SQLITE_STATIC,
        )) {
            const cause = c.sqlite3_errmsg(self._db._db);
            std.log.err("sqlite3_bind_blob failed because {s}", .{cause});
            return error.StmtBindFailed;
        }
    }

    pub fn step(self: *Statement) !bool {
        return switch (c.sqlite3_step(self._stmt)) {
            c.SQLITE_ROW => true,
            c.SQLITE_DONE => false,
            else => {
                const cause = c.sqlite3_errmsg(self._db._db);
                std.log.err("sqlite3_step failed because {s}", .{cause});
                return error.StmtStepFailed;
            },
        };
    }

    pub fn columnText(self: *Statement, column: u16) []const u8 {
        const ptr = c.sqlite3_column_text(self._stmt, column);
        const len: usize = @intCast(c.sqlite3_column_bytes(self._stmt, column));
        if (ptr == null or len == 0) {
            std.log.err("sqlite3_column_text returned a null or zero-length string; falling back to empty string", .{});
        }
        return ptr[0..len];
    }

    pub fn columnInt(self: *Statement, column: u16) i32 {
        return @intCast(c.sqlite3_column_int(self._stmt, column));
    }

    pub fn reset(self: *Statement) void {
        if (c.SQLITE_OK != c.sqlite3_reset(self._stmt)) {
            const cause = c.sqlite3_errmsg(self._db._db);
            std.log.err("sqlite3_reset failed because {s}", .{cause});
        }
    }
};

test {
    _ = &Statement.bindBlob;
    _ = &Statement.bindText;
    _ = &Statement.columnInt;
    _ = &Statement.columnText;
    _ = &Statement.deinit;
    _ = &Statement.init;
    _ = &Statement.reset;
    _ = &Statement.step;
}

test "open, create schema, close" {
    var db = try Db.init(":memory:");
    defer db.deinit();
    try db.exec(schema);
}
