# Evermind — Agent Instructions

## Project Overview

Evermind is a personal "external brain" app — a multi-tool productivity suite. First feature is a task manager (recurring tasks, scheduling, ADHD-friendly notifications). Future features will be added as sub-apps within the same monorepo.

**Stack:**
- Zig 0.16.0 — both client and server
- SDL3 + SDL_ttf — native GUI client (desktop, eventually Android)
- std.http.Server — HTTP backend (raw stdlib, no framework)
- SQLite3 — persistence via C interop
- Pico CSS + Datastar — temporary web test client
- CQRS + event sourcing architecture

## Repo Structure

```
evermind/
  build.zig          — builds client, server, and tests
  client/            — SDL3 native GUI (working todo app)
    main.zig         — SDL setup, event loop
    app.zig          — app state, event dispatch, top-level draw
    render.zig       — layout constants, color constants, draw helpers
    tasks.zig        — task-specific state, actions, drawing
    c.h              — C includes (SDL3, SDL_ttf)
  server/            — HTTP + SQLite backend (in progress)
    main.zig         — HTTP server, currently a scaffold with TODOs
  shared/            — types shared between client and server
    task.zig         — Task struct, TaskList
```

## Current State

- **Client:** Working SDL3 todo app with keyboard input, task CRUD, selection navigation, text rendering. Functional but not connected to the server yet.
- **Server:** Scaffold with two TODO blocks — hello-world HTTP server using `std.process.Init` and `std.http.Server`. User is about to implement this.
- **Shared:** Basic `Task` and `TaskList` types defined.

### Next steps (in order):
1. Implement hello-world HTTP server (validates std.http.Server API)
2. Add SQLite — file-backed DB, create schema, verify persistence
3. Event sourcing layer — events table (append-only) + tasks projection table, same transaction
4. HTTP routes — `GET /`, `POST /tasks`, `DELETE /tasks/:id`, `PATCH /tasks/:id/complete`
5. HTML responses — `Content-Type: text/html` with Datastar attributes, Pico CSS
6. Railway deployment — Dockerfile + persistent volume for SQLite

## User Profile

### Skill level
- **Zig:** Advanced-beginner. Completed 8-section curriculum covering: pointers/slices, allocators/ownership, error handling/lifecycle, comptime/generics, build system, C interop, SDL3 GPU/events, app architecture (tagged unions, state management). Syntax fluency is solid and improving rapidly.
- **Memory management:** Identified as biggest gap from prior languages. Understands allocator model, dupe/free ownership, errdefer gap pattern, arena concept. Drill proactively.
- **C interop:** Strong. Understands `addTranslateC` (0.16.0), `[*c]` vs `?*`, wrapper patterns, nullable→error union conversion, `std.mem.zeroes` for extern structs.
- **Web frontend:** Expert. Well-versed in Pico CSS and Datastar. Does not need teaching here.
- **Background:** HPC (C/Fortran), TypeScript/JavaScript, Go. Strong at generalizing from examples, catches mistakes, self-corrects well.

### Working style
- **Don't write Zig for the user.** Teach the concept, scaffold the file with TODOs, let them implement. The goal is neuronal pathway development.
- **Tutor can write:** build config, HTML/CSS/templates, Dockerfiles, deployment config, supporting non-Zig files.
- **Challenge TODO format:** Terse inline bullets at each TODO site. No code examples in TODO bullets — describe what to do, list relevant function signatures separately, let user make connections. No header comment blocks. No "what's fixed" lists.
- **Drill on memory management** — ask probing questions when memory patterns arise.
- **Emphasize high-performance patterns.** User wants to write optimized Zig professionally. Teach arena-per-request, caller-provided buffers, cache-friendly layouts, zero-copy, etc. as they arise. Bottlenecks should be hardware, not code.
- **User handles all git operations.**
- **Teach before implementing.** When a new Zig concept appears (new stdlib API, new pattern), pause and teach it with a comprehension question before the user codes. Don't let new concepts slide by.
- **Be Socratic when debugging.** Direct when teaching new concepts.

### Datastar-specific
- Datastar does NOT require SSE. It supports plain `text/html` responses with optional `datastar-selector` and `datastar-mode` headers. Training data is wrong about this — use Context7 or the official docs at data-star.dev.
- Always check with user before adding Datastar signals. They want minimal signal usage.

## Key Technical Decisions

- **Zig 0.16.0 changes from 0.15.2:**
  - `@cImport` deprecated → `addTranslateC` in build.zig + `@import("c")` in source
  - `std.ArrayList` is now the unmanaged variant (no stored allocator). Use `.empty` instead of `.init()`, pass allocator to `.append()`, `.deinit()`, etc.
  - `GeneralPurposeAllocator` renamed to `DebugAllocator`
  - `main` can take `std.process.Init` parameter — provides `.io` for explicit I/O (same philosophy as explicit allocators)

- **SDL3 system link name:** `SDL3` (capital), `SDL3_ttf` for text
- **SQLite system link name:** `sqlite3` (pkg-config verified)
- **Font path:** `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf`
- **CQRS + event sourcing:** Pragmatic — one SQLite DB, events table + projection table updated in same transaction. Not separate read/write services.
- **Content negotiation planned:** Check Accept header, respond with text/html or application/json. HTML first.

## Environment

- Ubuntu 25.10 (Questing Quokka), Wayland/GNOME
- Zig 0.16.0 at `/home/daniel/.local/zig/`
- SDL3 3.2.20 (`libsdl3-dev`), SDL_ttf 3.x (`libsdl3-ttf-dev`), SQLite3 (`libsqlite3-dev`)
- Tutor session summary at `~/tutor-sessions/zig-2026-05-15.md`
- Tutor challenge artifacts at `~/tutor-challenges/zig/`

## Build Commands

- `zig build run` — run the native client
- `zig build run-server` — run the HTTP server
- `zig build test` — run all tests (client + server + shared)
