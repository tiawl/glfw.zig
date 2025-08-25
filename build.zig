const std = @import("std");
const toolbox_pkg = @import("toolbox");
const Toolbox = toolbox_pkg.Toolbox;

fn update(toolbox: *Toolbox) !void {
    const glfw_path = try toolbox.buildRootJoin(&.{
        "glfw",
    });

    std.fs.deleteTreeAbsolute(glfw_path) catch |err| {
        switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
    };

    try toolbox.clone(.glfw, glfw_path);

    var glfw_dir = try std.fs.openDirAbsolute(glfw_path, .{
        .iterate = true,
    });
    defer glfw_dir.close();

    var it = glfw_dir.iterate();
    while (try it.next()) |*entry| {
        if (!std.mem.eql(u8, entry.name, "src") and !std.mem.eql(u8, entry.name, "include")) {
            try std.fs.deleteTreeAbsolute(toolbox.pathJoin(&.{
                glfw_path, entry.name,
            }));
        }
    }

    try toolbox.clean(&.{
        "glfw",
    }, &.{});
}

const FromZon = toolbox_pkg.Repositories(.{
    .toolbox, .vulkan_zig, .wayland_zig, .X11_zig,
});

const DuringExec = toolbox_pkg.Repositories(.{
    .glfw,
});

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    var toolbox = try Toolbox.init(FromZon, DuringExec, builder, optimize, .glfw_zig, "0xcba456a5a3d8bb36", &.{
        "glfw",
    }, .{
        .toolbox = .{
            .name = "tiawl/toolbox",
            .host = .github,
            .ref = .tag,
        },
        .vulkan_zig = .{
            .name = "tiawl/vulkan.zig",
            .host = .github,
            .ref = .tag,
        },
        .wayland_zig = .{
            .name = "tiawl/wayland.zig",
            .host = .github,
            .ref = .tag,
        },
        .X11_zig = .{
            .name = "tiawl/X11.zig",
            .host = .github,
            .ref = .tag,
        },
    }, .{
        .glfw = .{
            .name = "glfw/glfw",
            .host = .github,
            .ref = .tag,
        },
    });
    defer toolbox.deinit();

    if (toolbox.getUpdate()) try update(&toolbox);

    const lib = builder.addLibrary(.{
        .name = "glfw",
        .root_module = std.Build.Module.create(builder, .{
            .root_source_file = builder.addWriteFiles().add("empty.zig", ""),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    var root_dir = try builder.build_root.handle.openDir(".", .{
        .iterate = true,
    });
    defer root_dir.close();

    var walk = try root_dir.walk(builder.allocator);
    while (try walk.next()) |*entry| {
        if (std.mem.startsWith(u8, entry.path, "glfw") and entry.kind == .directory) {
            toolbox.addInclude(lib, entry.path);
        }
    }

    toolbox.addHeader(lib, try builder.build_root.join(builder.allocator, &.{
        "glfw", "include", "GLFW",
    }), "GLFW", &.{
        ".h",
    });

    const vulkan_dep = builder.dependency("vulkan_zig", .{
        .target = target,
        .optimize = optimize,
    });

    lib.installLibraryHeaders(vulkan_dep.artifact("vulkan"));

    const src_path = try builder.build_root.join(builder.allocator, &.{
        "glfw", "src",
    });

    var src_dir = try std.fs.openDirAbsolute(src_path, .{
        .iterate = true,
    });
    defer src_dir.close();

    switch (target.result.os.tag) {
        .windows => {
            lib.linkSystemLibrary("gdi32");
            lib.linkSystemLibrary("user32");
            lib.linkSystemLibrary("shell32");

            const flags = [_][]const u8{
                "-D_GLFW_WIN32", "-Isrc",
            };

            var it = src_dir.iterate();
            while (try it.next()) |*entry| {
                if ((!std.mem.startsWith(u8, entry.name, "linux_") and
                    !std.mem.startsWith(u8, entry.name, "posix_") and
                    !std.mem.startsWith(u8, entry.name, "xkb_") and
                    !std.mem.startsWith(u8, entry.name, "glx_") and
                    !std.mem.startsWith(u8, entry.name, "x11_") and
                    !std.mem.startsWith(u8, entry.name, "cocoa_") and
                    !std.mem.startsWith(u8, entry.name, "nsgl_") and
                    !std.mem.startsWith(u8, entry.name, "wl_")) and
                    toolbox_pkg.isCSource(entry.name) and entry.kind == .file)
                {
                    try toolbox.addSource(lib, src_path, entry.name, &flags);
                }
            }
        },
        .macos => {
            lib.linkFramework("Cocoa");
            lib.linkFramework("CoreFoundation");
            lib.linkFramework("IOKit");

            const flags = [_][]const u8{
                "-D_GLFW_COCOA",
                "-Isrc",
            };

            var it = src_dir.iterate();
            while (try it.next()) |*entry| {
                if ((!std.mem.startsWith(u8, entry.name, "linux_") and
                    !std.mem.startsWith(u8, entry.name, "xkb_") and
                    !std.mem.startsWith(u8, entry.name, "glx_") and
                    !std.mem.startsWith(u8, entry.name, "x11_") and
                    !std.mem.startsWith(u8, entry.name, "wgl_") and
                    !std.mem.startsWith(u8, entry.name, "win32_") and
                    !std.mem.startsWith(u8, entry.name, "wl_")) and
                    (toolbox_pkg.isCSource(entry.name) or std.mem.endsWith(u8, entry.name, ".m")) and entry.kind == .file)
                {
                    try toolbox.addSource(lib, src_path, entry.name, &flags);
                }
            }
        },
        else => {
            const X11_dep = builder.dependency("X11_zig", .{
                .target = target,
                .optimize = optimize,
            });

            const wayland_dep = builder.dependency("wayland_zig", .{
                .target = target,
                .optimize = optimize,
            });

            lib.linkLibrary(X11_dep.artifact("X11"));
            lib.linkLibrary(wayland_dep.artifact("wayland"));
            lib.installLibraryHeaders(X11_dep.artifact("X11"));
            lib.installLibraryHeaders(wayland_dep.artifact("wayland"));

            const flags = [_][]const u8{
                "-D_GLFW_X11", "-D_GLFW_WAYLAND", "-Wno-implicit-function-declaration", "-Isrc",
            };

            var it = src_dir.iterate();
            while (try it.next()) |*entry| {
                if ((!std.mem.startsWith(u8, entry.name, "wgl_") and
                    !std.mem.startsWith(u8, entry.name, "win32_") and
                    !std.mem.startsWith(u8, entry.name, "cocoa_") and
                    !std.mem.startsWith(u8, entry.name, "nsgl_")) and
                    toolbox_pkg.isCSource(entry.name) and entry.kind == .file)
                {
                    try toolbox.addSource(lib, src_path, entry.name, &flags);
                }
            }

            lib.root_module.addCMacro("WL_MARSHAL_FLAG_DESTROY", "1");
        },
    }

    builder.installArtifact(lib);
}
