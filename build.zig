const std = @import ("std");
const pkg = .{ .name = "glfw.zig", .version = "3.4", };

fn exec (builder: *std.Build, argv: [] const [] const u8) !void
{
  var stdout = std.ArrayList (u8).init (builder.allocator);
  var stderr = std.ArrayList (u8).init (builder.allocator);
  errdefer { stdout.deinit (); stderr.deinit (); }

  std.debug.print ("\x1b[35m[{s}]\x1b[0m\n", .{ try std.mem.join (builder.allocator, " ", argv), });

  var child = std.ChildProcess.init (argv, builder.allocator);

  child.stdin_behavior = .Ignore;
  child.stdout_behavior = .Pipe;
  child.stderr_behavior = .Pipe;

  try child.spawn ();
  try child.collectOutput (&stdout, &stderr, 1000);

  const term = try child.wait ();

  if (stdout.items.len > 0) std.debug.print ("{s}", .{ stdout.items, });
  if (stderr.items.len > 0 and !std.meta.eql (term, std.ChildProcess.Term { .Exited = 0, })) std.debug.print ("\x1b[31m{s}\x1b[0m", .{ stderr.items, });
  try std.testing.expectEqual (term, std.ChildProcess.Term { .Exited = 0, });
}

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

  try exec (builder, &[_][] const u8 { "git", "clone", "https://github.com/glfw/glfw.git", glfw_path, });
  try exec (builder, &[_][] const u8 { "git", "-C", glfw_path, "checkout", pkg.version, });

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
  lib.linkSystemLibrary ("X11");
  lib.linkSystemLibrary ("xkbcommon");

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

  lib.installHeadersDirectory (try std.fs.path.join (builder.allocator, &.{ "glfw", "include", "GLFW", }), "GLFW");
  std.debug.print ("[glfw headers dir] {s}\n", .{ try builder.build_root.join (builder.allocator, &.{ "glfw", "include", "GLFW", }), });

  const vulkan_dep = builder.dependency ("vulkan", .{
    .target = target,
    .optimize = optimize,
  });

  const wayland_dep = builder.dependency ("wayland", .{
    .target = target,
    .optimize = optimize,
  });

  lib.linkLibrary (wayland_dep.artifact ("wayland"));
  lib.installLibraryHeaders (vulkan_dep.artifact ("vulkan"));
  lib.installLibraryHeaders (wayland_dep.artifact ("wayland"));

  var sources = try std.BoundedArray ([] const u8, 64).init (0);

  const src_path = try builder.build_root.join (builder.allocator, &.{ "glfw", "src", });
  var src = try std.fs.openDirAbsolute (src_path, .{ .iterate = true, });
  defer src.close ();

  var it = src.iterate ();
  while (try it.next ()) |*entry|
  {
    if ((!std.mem.startsWith (u8, entry.name, "wgl_") and
      !std.mem.startsWith (u8, entry.name, "win32_") and
      !std.mem.startsWith (u8, entry.name, "cocoa_") and
      !std.mem.startsWith (u8, entry.name, "nsgl_")) and
      std.mem.endsWith (u8, entry.name, ".c") and entry.kind == .file)
        try sources.append (try std.fs.path.join (builder.allocator, &.{ src_path , entry.name, }));
  }

  lib.root_module.addCMacro ("WL_MARSHAL_FLAG_DESTROY", "1");

  for (sources.slice ()) |source| std.debug.print ("[glfw source] {s}\n", .{ source, });
  lib.addCSourceFiles (.{
    .files = sources.slice (),
    .flags = &.{
      "-D_GLFW_X11", "-D_GLFW_WAYLAND", "-Wno-implicit-function-declaration", "-Isrc",
    },
  });

  builder.installArtifact (lib);
}
