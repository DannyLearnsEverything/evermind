const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── Shared module (imported by both client and server) ────────────────
    const shared_mod = b.createModule(.{
        .root_source_file = b.path("shared/task.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ── Client (SDL3 + SDL_ttf GUI) ──────────────────────────────────────
    const translate_client_c = b.addTranslateC(.{
        .root_source_file = b.path("client/c.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_client_c.linkSystemLibrary("SDL3", .{});
    translate_client_c.linkSystemLibrary("SDL3_ttf", .{});

    const client = b.addExecutable(.{
        .name = "evermind",
        .root_module = b.createModule(.{
            .root_source_file = b.path("client/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "c", .module = translate_client_c.createModule() },
                .{ .name = "shared", .module = shared_mod },
            },
        }),
    });
    b.installArtifact(client);

    const run_client = b.addRunArtifact(client);
    run_client.step.dependOn(b.getInstallStep());
    b.step("run", "Run the client").dependOn(&run_client.step);

    // ── Server (HTTP + SQLite — stub for now) ────────────────────────────
    const translate_server_c = b.addTranslateC(.{
        .root_source_file = b.path("server/c.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_server_c.linkSystemLibrary("sqlite3", .{});

    const server = b.addExecutable(.{
        .name = "evermind-server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("server/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "c", .module = translate_server_c.createModule() },
                .{ .name = "shared", .module = shared_mod },
            },
        }),
    });
    b.installArtifact(server);

    const run_server = b.addRunArtifact(server);
    run_server.step.dependOn(b.getInstallStep());
    b.step("run-server", "Run the server").dependOn(&run_server.step);

    // ── Tests ────────────────────────────────────────────────────────────
    const client_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("client/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "c", .module = translate_client_c.createModule() },
                .{ .name = "shared", .module = shared_mod },
            },
        }),
    });

    const server_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("server/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "shared", .module = shared_mod },
                .{ .name = "c", .module = translate_server_c.createModule() },
            },
        }),
    });

    const shared_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("shared/task.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&b.addRunArtifact(client_tests).step);
    test_step.dependOn(&b.addRunArtifact(server_tests).step);
    test_step.dependOn(&b.addRunArtifact(shared_tests).step);
}
