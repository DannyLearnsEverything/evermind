const std = @import("std");
const net = std.Io.net;
const db = @import("db.zig");

pub fn main(init: std.process.Init) !void {

    // Initialize DB
    var db_connection: db.Db = try .init("evermind.db");
    defer db_connection.deinit();
    try db_connection.exec(db.schema);

    const io = init.io;

    const addr = try net.IpAddress.parse("0.0.0.0", 8080);
    var netServer = try addr.listen(io, .{ .reuse_address = true });
    defer netServer.deinit(io);
    std.log.info("Listening on :8080", .{});

    while (true) {
        const stream = netServer.accept(io) catch |cause| {
            std.log.err("Failed to accept incoming request because {s}", .{@errorName(cause)});
            continue;
        };
        handleConnection(io, stream);
    }
}

fn handleConnection(io: std.Io, stream: net.Stream) void {
    defer stream.close(io);

    // - Declare stack buffers for reader/writer (4096 bytes each)
    var read_buffer: [1 << 12]u8 = undefined;
    var write_buffer: [1 << 12]u8 = undefined;

    var reader = stream.reader(io, &read_buffer);
    var writer = stream.writer(io, &write_buffer);

    var httpServer = std.http.Server.init(&reader.interface, &writer.interface);

    var request = httpServer.receiveHead() catch |cause| {
        std.log.err("Failed to receive head because {s}", .{@errorName(cause)});
        return;
    };

    request.respond("Hello from Evermind!", .{
        .status = .ok,
        .extra_headers = &.{.{
            .name = "Content-Type",
            .value = "text/html",
        }},
    }) catch return;
}
