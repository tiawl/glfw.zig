const std = @import("std");
const build_zig_zon = @import("build.zig.zon");
const toolbox = @import("toolbox");
const VerboseBuilder = toolbox.VerboseBuilder;

fn updateFn(pkg_builder: *VerboseBuilder) !void {
    try pkg_builder.remove(&.{"glfw"});
    try pkg_builder.make(&.{"glfw"});

    const glfw_dep = pkg_builder.verboseDependency("glfw");
    var glfw_builder = VerboseBuilder.initFromDependency(glfw_dep);

    for ([_][]const u8{ "src", "include" }) |path| {
        try pkg_builder.make(&.{ "glfw", path });
        while (try glfw_builder.walk(&.{path})) |*entry| {
            switch (entry.kind) {
                .file => if (toolbox.isCFile(entry.basename) or toolbox.isObjCSource(entry.basename)) try pkg_builder.copy(&.{ "glfw", path, entry.path }, &glfw_builder, &.{ path, entry.path }),
                .directory => try pkg_builder.make(&.{ "glfw", path, entry.path }),
                else => {},
            }
        }
    }
}

fn buildFn(pkg_builder: *VerboseBuilder) !void {
    const lib = pkg_builder.addLibrary("glfw");
    pkg_builder.unsanitizeC(lib);
    pkg_builder.linkLibC(lib);

    while (try pkg_builder.walk(&.{ "glfw", "include" })) |*entry| {
        if (toolbox.isCHeader(entry.basename)) pkg_builder.installHeader(lib, &.{ "glfw", "include", entry.path }, &.{entry.path});
    }

    const vulkan_dep = pkg_builder.verboseDependency("vulkan_zig");
    pkg_builder.installLibraryHeaders(lib, pkg_builder.artifact(vulkan_dep, "vulkan"));

    switch (pkg_builder.getOs()) {
        .windows => {
            pkg_builder.linkSystemLibrary(lib, "gdi32");
            pkg_builder.linkSystemLibrary(lib, "user32");
            pkg_builder.linkSystemLibrary(lib, "shell32");

            while (try pkg_builder.iterate(&.{ "glfw", "src" })) |*entry| {
                if ((!std.mem.startsWith(u8, entry.name, "linux_") and
                    !std.mem.startsWith(u8, entry.name, "posix_") and
                    !std.mem.startsWith(u8, entry.name, "xkb_") and
                    !std.mem.startsWith(u8, entry.name, "glx_") and
                    !std.mem.startsWith(u8, entry.name, "x11_") and
                    !std.mem.startsWith(u8, entry.name, "cocoa_") and
                    !std.mem.startsWith(u8, entry.name, "nsgl_") and
                    !std.mem.startsWith(u8, entry.name, "wl_")) and
                    toolbox.isCSource(entry.name) and entry.kind == .file)
                {
                    pkg_builder.addCSource(lib, &.{ "glfw", "src", entry.name }, &.{ "-D_GLFW_WIN32", "-Isrc" });
                }
            }
        },
        .macos => {
            pkg_builder.linkFramework(lib, "Cocoa");
            pkg_builder.linkFramework(lib, "CoreFoundation");
            pkg_builder.linkFramework(lib, "IOKit");

            while (try pkg_builder.iterate(&.{ "glfw", "src" })) |*entry| {
                if ((!std.mem.startsWith(u8, entry.name, "linux_") and
                    !std.mem.startsWith(u8, entry.name, "xkb_") and
                    !std.mem.startsWith(u8, entry.name, "glx_") and
                    !std.mem.startsWith(u8, entry.name, "x11_") and
                    !std.mem.startsWith(u8, entry.name, "wgl_") and
                    !std.mem.startsWith(u8, entry.name, "win32_") and
                    !std.mem.startsWith(u8, entry.name, "wl_")) and
                    (toolbox.isCSource(entry.name) or toolbox.isObjCSource(entry.name)) and entry.kind == .file)
                {
                    pkg_builder.addCSource(lib, &.{ "glfw", "src", entry.name }, &.{ "-D_GLFW_COCOA", "-Isrc" });
                }
            }
        },
        else => {
            const x11_dep = pkg_builder.verboseDependency("X11_zig");
            const wayland_dep = pkg_builder.verboseDependency("wayland_zig");
            const x11_artifact = pkg_builder.artifact(x11_dep, "X11");
            const wayland_artifact = pkg_builder.artifact(wayland_dep, "wayland");

            for ([_]*std.Build.Step.Compile{ x11_artifact, wayland_artifact }) |artifact| {
                pkg_builder.addIncludePathsFromLib(@TypeOf(lib.*), lib, artifact);
                pkg_builder.linkLibrary(lib, artifact);
                pkg_builder.installLibraryHeaders(lib, artifact);
            }

            while (try pkg_builder.iterate(&.{ "glfw", "src" })) |*entry| {
                if ((!std.mem.startsWith(u8, entry.name, "wgl_") and
                    !std.mem.startsWith(u8, entry.name, "win32_") and
                    !std.mem.startsWith(u8, entry.name, "cocoa_") and
                    !std.mem.startsWith(u8, entry.name, "nsgl_")) and
                    toolbox.isCSource(entry.name) and entry.kind == .file)
                {
                    pkg_builder.addCSource(lib, &.{ "glfw", "src", entry.name }, &.{ "-D_GLFW_X11", "-D_GLFW_WAYLAND", "-Wno-implicit-function-declaration", "-Isrc" });
                }
            }
        },
    }

    pkg_builder.addInclude(lib, &.{ "glfw", "include" });
    pkg_builder.installArtifact(lib);
}

pub fn build(builder: *std.Build) !void {
    var pkg_builder = try VerboseBuilder.init(builder, @tagName(build_zig_zon.name), buildFn, updateFn);

    try pkg_builder.fetch(@TypeOf(build_zig_zon.dependencies), build_zig_zon.dependencies, pkg_builder.ptrCwd());
    try pkg_builder.update();
    try pkg_builder.build();
}
