# glfw.zig

This is a fork of [hexops/glfw](https://github.com/hexops/glfw) which is itself a fork of [glfw/glfw](https://github.com/glfw/glfw).

## Why this forkception ?

The intention under this fork is the same as hexops had when they forked [glfw/glfw](https://github.com/glfw/glfw): package GLFW for Zig. So:
* unnecessary files have been deleted,
* the build system has been replaced with `build.zig`.
However this repository has subtle differences for maintainability tasks:
* no shell scripting,
* a cron is triggered every day to check [glfw/glfw](https://github.com/glfw/glfw) and to update this repository if a new release is available,
* no support for macOS.

You can find the repository version used here:
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
* [tiawl/spaceporn-dep-action-bot](https://github.com/tiawl/spaceporn-dep-action-bot)
* [tiawl/spaceporn-dep-action-ci](https://github.com/tiawl/spaceporn-dep-action-ci)
* [tiawl/spaceporn-dep-action-cd-ping](https://github.com/tiawl/spaceporn-dep-action-cd-ping)
* [tiawl/spaceporn-dep-action-cd-pong](https://github.com/tiawl/spaceporn-dep-action-cd-pong)

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .versions folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```
