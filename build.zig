const std = @import ("std");
const toolbox = @import ("toolbox");

fn update (builder: *std.Build,
  dependencies: *const toolbox.Dependencies) !void
{
  const glfw_path = try builder.build_root.join (builder.allocator,
    &.{ "glfw", });

  std.fs.deleteTreeAbsolute (glfw_path) catch |err|
  {
    switch (err)
    {
      error.FileNotFound => {},
      else => return err,
    }
  };

  try dependencies.clone (builder, "glfw", glfw_path);

  var glfw_dir = try std.fs.openDirAbsolute (glfw_path, .{ .iterate = true, });
  defer glfw_dir.close ();

  var it = glfw_dir.iterate ();
  while (try it.next ()) |*entry|
  {
    if (!std.mem.eql (u8, entry.name, "src") and
      !std.mem.eql (u8, entry.name, "include"))
        try std.fs.deleteTreeAbsolute (try std.fs.path.join (
          builder.allocator, &.{ glfw_path, entry.name, }));
  }

  try toolbox.clean (builder, &.{ "glfw", }, &.{});
}

pub fn build (builder: *std.Build) !void
{
  const target = builder.standardTargetOptions (.{});
  const optimize = builder.standardOptimizeOption (.{});

  const dependencies = try toolbox.Dependencies.init (builder, "glfw.zig",
  .{
     .toolbox = .{
       .name = "tiawl/toolbox",
       .host = toolbox.Repository.Host.github,
     },
     .vulkan = .{
       .name = "tiawl/vulkan.zig",
       .host = toolbox.Repository.Host.github,
     },
     .wayland = .{
       .name = "tiawl/wayland.zig",
       .host = toolbox.Repository.Host.github,
     },
     .X11 = .{
       .name = "tiawl/X11.zig",
       .host = toolbox.Repository.Host.github,
     },
   }, .{
     .glfw = .{
       .name = "glfw/glfw",
       .host = toolbox.Repository.Host.github,
     },
   });

  if (builder.option (bool, "update", "Update binding") orelse false)
    try update (builder, &dependencies);

  const lib = builder.addStaticLibrary (.{
    .name = "glfw",
    .root_source_file = builder.addWriteFiles ().add ("empty.c", ""),
    .target = target,
    .optimize = optimize,
  });

  lib.linkLibC ();

  var root_dir = try builder.build_root.handle.openDir (".",
    .{ .iterate = true, });
  defer root_dir.close ();

  var walk = try root_dir.walk (builder.allocator);
  while (try walk.next ()) |*entry|
  {
    if (std.mem.startsWith (u8, entry.path, "glfw") and
      entry.kind == .directory) toolbox.addInclude (lib, entry.path);
  }

  toolbox.addHeader (lib, try builder.build_root.join (builder.allocator,
    &.{ "glfw", "include", "GLFW", }), "GLFW", &.{ ".h", });

  const vulkan_dep = builder.dependency ("vulkan", .{
    .target = target,
    .optimize = optimize,
  });

  lib.installLibraryHeaders (vulkan_dep.artifact ("vulkan"));

  const src_path = try builder.build_root.join (builder.allocator,
    &.{ "glfw", "src", });
  var src_dir = try std.fs.openDirAbsolute (src_path, .{ .iterate = true, });
  defer src_dir.close ();

  switch (target.result.os.tag)
  {
    .windows => {
      lib.linkSystemLibrary ("gdi32");
      lib.linkSystemLibrary ("user32");
      lib.linkSystemLibrary ("shell32");

      const flags = [_][] const u8 { "-D_GLFW_WIN32", "-Isrc", };

      var it = src_dir.iterate ();
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
          toolbox.isCSource (entry.name) and entry.kind == .file)
            try toolbox.addSource (lib, src_path, entry.name, &flags);
      }
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

      const flags = [_][] const u8
      {
        "-D_GLFW_X11", "-D_GLFW_WAYLAND",
        "-Wno-implicit-function-declaration", "-Isrc",
      };

      var it = src_dir.iterate ();
      while (try it.next ()) |*entry|
      {
        if ((!std.mem.startsWith (u8, entry.name, "wgl_") and
          !std.mem.startsWith (u8, entry.name, "win32_") and
          !std.mem.startsWith (u8, entry.name, "cocoa_") and
          !std.mem.startsWith (u8, entry.name, "nsgl_")) and
          toolbox.isCSource (entry.name) and entry.kind == .file)
            try toolbox.addSource (lib, src_path, entry.name, &flags);
      }

      lib.root_module.addCMacro ("WL_MARSHAL_FLAG_DESTROY", "1");
    },
  }

  builder.installArtifact (lib);
}
