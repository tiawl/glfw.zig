# glfw.zig

This is a fork of [hexops/glfw][1] which is itself a fork of [glfw/glfw][2].

## Why this forkception ?

The intention under this fork is the same as [hexops][13] had when they forked [glfw/glfw][2]: package it for [Zig][3]. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`.
However this repository has subtle differences for maintainability tasks:
* No shell scripting,
* A cron runs every day to check [glfw/glfw][2]. Then it updates this repository if a new release is available,
* No support for macOS.

Here the repositories' version used by this fork:
* [glfw/glfw](https://github.com/tiawl/glfw.zig/blob/trunk/.versions/glfw)

## CICD reminder

These repositories are automatically updated when a new release is available:
* [tiawl/cimgui.zig][4]

This repository is automatically updated when a new release is available from these repositories:
* [glfw/glfw][2]
* [tiawl/toolbox][5]
* [tiawl/vulkan.zig][6]
* [tiawl/wayland.zig][7]
* [tiawl/X11.zig][8]
* [tiawl/spaceporn-action-bot][9]
* [tiawl/spaceporn-action-ci][10]
* [tiawl/spaceporn-action-cd-ping][11]
* [tiawl/spaceporn-action-cd-pong][12]

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .versions folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

The unprotected parts of this repository are under MIT License. For everything else, see with their respective owners.

[1]:https://github.com/hexops/glfw
[2]:https://github.com/glfw/glfw
[3]:https://github.com/ziglang/zig
[4]:https://github.com/tiawl/cimgui.zig
[5]:https://github.com/tiawl/toolbox
[6]:https://github.com/tiawl/vulkan.zig
[7]:https://github.com/tiawl/wayland.zig
[8]:https://github.com/tiawl/X11.zig
[9]:https://github.com/tiawl/spaceporn-action-bot
[10]:https://github.com/tiawl/spaceporn-action-ci
[11]:https://github.com/tiawl/spaceporn-action-cd-ping
[12]:https://github.com/tiawl/spaceporn-action-cd-pong
[13]:https://github.com/hexops
