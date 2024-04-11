const std = @import ("std");
const toolbox = @import ("toolbox");
const pkg = .{ .name = "glfw.zig", .version = "3.4", };

fn update (builder: *std.Build) !void
{
  const glfw_path = try builder.build_root.join (builder.allocator, &.{ "glfw", });

  std.fs.deleteTreeAbsolute (glfw_path) catch |err|
  {
    switch (err)
    {
      error.FileNotFound => {},
      else => return err,
    }
  };

  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://github.com/glfw/glfw.git", glfw_path, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", glfw_path, "checkout", pkg.version, }, });

  var glfw = try std.fs.openDirAbsolute (glfw_path, .{ .iterate = true, });
  defer glfw.close ();

  var it = glfw.iterate ();
  while (try it.next ()) |*entry|
  {
    if (!std.mem.eql (u8, entry.name, "src") and
      !std.mem.eql (u8, entry.name, "include"))
        try std.fs.deleteTreeAbsolute (try std.fs.path.join (builder.allocator, &.{ glfw_path, entry.name, }));
  }
}

pub fn build (builder: *std.Build) !void
{
  const target = builder.standardTargetOptions (.{});
  const optimize = builder.standardOptimizeOption (.{});

  if (builder.option (bool, "update", "Update binding") orelse false) try update (builder);

  const lib = builder.addStaticLibrary (.{
    .name = "glfw",
    .root_source_file = builder.addWriteFiles ().add ("empty.c", ""),
    .target = target,
    .optimize = optimize,
  });

  lib.linkLibC ();

  var includes = try std.BoundedArray ([] const u8, 64).init (0);

  var root = try builder.build_root.handle.openDir (".", .{ .iterate = true, });
  defer root.close ();

  var walk = try root.walk (builder.allocator);
  while (try walk.next ()) |*entry|
  {
    if (std.mem.startsWith (u8, entry.path, "glfw") and entry.kind == .directory)
      try includes.append (builder.dupe (entry.path));
  }

  for (includes.slice ()) |include|
  {
    std.debug.print ("[glfw include] {s}\n", .{ try builder.build_root.join (builder.allocator, &.{ include, }), });
    lib.addIncludePath (.{ .path = include, });
  }

  lib.installHeadersDirectory (.{ .path = try std.fs.path.join (builder.allocator, &.{ "glfw", "include", "GLFW", }), }, "GLFW", .{ .include_extensions = &.{ ".h", }, });
  std.debug.print ("[glfw headers dir] {s}\n", .{ try builder.build_root.join (builder.allocator, &.{ "glfw", "include", "GLFW", }), });

  const vulkan_dep = builder.dependency ("vulkan", .{
    .target = target,
    .optimize = optimize,
  });

  lib.installLibraryHeaders (vulkan_dep.artifact ("vulkan"));

  var sources = try std.BoundedArray ([] const u8, 64).init (0);

  const src_path = try builder.build_root.join (builder.allocator, &.{ "glfw", "src", });
  var src = try std.fs.openDirAbsolute (src_path, .{ .iterate = true, });
  defer src.close ();

  switch (target.result.os.tag)
  {
    .windows => {
                  lib.linkSystemLibrary ("gdi32");
                  lib.linkSystemLibrary ("user32");
                  lib.linkSystemLibrary ("shell32");

                  var it = src.iterate ();
                  while (try it.next ()) |*entry|
                  {
                    if ((!std.mem.startsWith (u8, entry.name, "linux_") and
                      !std.mem.startsWith (u8, entry.name, "posix_") and
                      !std.mem.startsWith (u8, entry.name, "xkb_") and
                      !std.mem.startsWith (u8, entry.name, "glx_") and
                      !std.mem.startsWith (u8, entry.name, "x11_") and
                      !std.mem.startsWith (u8, entry.name, "cocoa_") and
                      !std.mem.startsWith (u8, entry.name, "nsgl_") and
                      !std.mem.startsWith (u8, entry.name, "wl_")) and
                      toolbox.is_c_source_file (entry.name) and entry.kind == .file)
                    {
                      std.debug.print ("[glfw source] {s}\n", .{ try std.fs.path.join (builder.allocator, &.{ src_path , entry.name, }), });
                      try sources.append (try std.fs.path.join (builder.allocator, &.{ "glfw", "src", builder.dupe (entry.name), }));
                    }
                  }

                  lib.addCSourceFiles (.{
                    .files = sources.slice (),
                    .flags = &.{ "-D_GLFW_WIN32", "-Isrc", },
                  });
                },
    .macos   => return error.MacOSUnsupported,
    else     => {
                  const X11_dep = builder.dependency ("X11", .{
                    .target = target,
                    .optimize = optimize,
                  });

                  const wayland_dep = builder.dependency ("wayland", .{
                    .target = target,
                    .optimize = optimize,
                  });

                  lib.linkLibrary (X11_dep.artifact ("X11"));
                  lib.linkLibrary (wayland_dep.artifact ("wayland"));
                  lib.installLibraryHeaders (X11_dep.artifact ("X11"));
                  lib.installLibraryHeaders (wayland_dep.artifact ("wayland"));

                  var it = src.iterate ();
                  while (try it.next ()) |*entry|
                  {
                    if ((!std.mem.startsWith (u8, entry.name, "wgl_") and
                      !std.mem.startsWith (u8, entry.name, "win32_") and
                      !std.mem.startsWith (u8, entry.name, "cocoa_") and
                      !std.mem.startsWith (u8, entry.name, "nsgl_")) and
                      toolbox.is_c_source_file (entry.name) and entry.kind == .file)
                    {
                      std.debug.print ("[glfw source] {s}\n", .{ try std.fs.path.join (builder.allocator, &.{ src_path , entry.name, }), });
                      try sources.append (try std.fs.path.join (builder.allocator, &.{ "glfw", "src", builder.dupe (entry.name), }));
                    }
                  }

                  lib.root_module.addCMacro ("WL_MARSHAL_FLAG_DESTROY", "1");

                  lib.addCSourceFiles (.{
                    .files = sources.slice (),
                    .flags = &.{
                      "-D_GLFW_X11", "-D_GLFW_WAYLAND", "-Wno-implicit-function-declaration", "-Isrc",
                    },
                  });
                },
  }

  builder.installArtifact (lib);
}
