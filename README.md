# glfw.zig

This is a fork of [hexops/glfw](https://github.com/hexops/glfw) which is itself a fork of [glfw/glfw](https://github.com/glfw/glfw).

## Why this forkception ?

The intention under this fork is the same as hexops had when they forked [glfw/glfw](https://github.com/glfw/glfw): package @glfw for @ziglang. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`.
However this repository has subtle differences for maintainability tasks:
* No shell scripting,
* A cron runs every day to check [glfw/glfw](https://github.com/glfw/glfw). Then it updates this repository if a new release is available,
* No support for macOS.

Here the repositories' version used by this fork:
* [glfw/glfw](https://github.com/tiawl/glfw.zig/blob/trunk/.versions/glfw)

## CICD reminder

These repositories are automatically updated when a new release is available:
* [tiawl/cimgui.zig](https://github.com/tiawl/cimgui.zig)

This repository is automatically updated when a new release is available from these repositories:
* [glfw/glfw](https://github.com/glfw/glfw)
* [tiawl/toolbox](https://github.com/tiawl/toolbox)
* [tiawl/vulkan.zig](https://github.com/tiawl/vulkan.zig)
* [tiawl/wayland.zig](https://github.com/tiawl/wayland.zig)
* [tiawl/X11.zig](https://github.com/tiawl/X11.zig)
* [tiawl/spaceporn-action-bot](https://github.com/tiawl/spaceporn-action-bot)
* [tiawl/spaceporn-action-ci](https://github.com/tiawl/spaceporn-action-ci)
* [tiawl/spaceporn-action-cd-ping](https://github.com/tiawl/spaceporn-action-cd-ping)
* [tiawl/spaceporn-action-cd-pong](https://github.com/tiawl/spaceporn-action-cd-pong)

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .versions folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

The unprotected parts of this repository are under MIT License. For everything else, see with their respective owners.
