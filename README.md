# glfw.zig

This is a fork of [hexops/glfw][1] which is itself a fork of [glfw/glfw][2].

## Why this forkception ?

The intention under this fork is the same as [hexops][9] had when they forked [glfw/glfw][2]: package it for [Zig][3]. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`.

However this repository has subtle differences for maintainability tasks:
* No shell scripting,
* A cron runs every day to check [glfw/glfw][2]. Then it updates this repository if a new release is available,
* No support for macOS.

## How to use it

The goal of this repository is not to provide a [Zig][3] binding for [glfw/glfw][2]. There are at least as many legit ways as possible to make a binding as there are active accounts on Github. So you are not going to find an answer for this question here. The point of this repository is to abstract the [glfw/glfw][2] compilation process with [Zig][3] (which is not new comers friendly and not easy to maintain) to let you focus on your application. So you can use **glfw.zig**:
- as raw (see GLFW examples [here](https://github.com/tiawl/cimgui.zig/blob/trunk/examples)),
- as a daily updated interface for your [Zig][3] binding of [glfw/glfw][2] (see [here][10] for a private usage).

## Important note

The current usage of this repository is centered around [tiawl/cimgui.zig][3] compilation. So for your usage it could break because some files have been filtered in the process. If it happens, open an issue: this repository is open to potential usage evolution.

## Dependencies

The [Zig][3] part of this package is relying on the latest [Zig][3] release (0.15.1) and will only be updated for the next one.

Here the repositories' version used by this fork:
* [glfw/glfw](https://github.com/tiawl/glfw.zig/blob/trunk/.references/glfw)

## CICD reminder

These repositories are automatically updated when a new release is available:
* [tiawl/cimgui.zig][4]

This repository is automatically updated when a new release is available from these repositories:
* [glfw/glfw][2]
* [tiawl/toolbox][5]
* [tiawl/vulkan.zig][6]
* [tiawl/wayland.zig][7]
* [tiawl/X11.zig][8]

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .references folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

This repository is not subject to a unique License:

The parts of this repository originated from this repository are dedicated to the public domain. See the LICENSE file for more details.

**For other parts, it is subject to the License restrictions their respective owners choosed. By design, the public domain code is incompatible with the License notion. In this case, the License prevails. So if you have any doubt about a file property, open an issue.**

[1]:https://github.com/hexops/glfw
[2]:https://github.com/glfw/glfw
[3]:https://github.com/ziglang/zig
[4]:https://github.com/tiawl/cimgui.zig
[5]:https://github.com/tiawl/toolbox
[6]:https://github.com/tiawl/vulkan.zig
[7]:https://github.com/tiawl/wayland.zig
[8]:https://github.com/tiawl/X11.zig
[9]:https://github.com/hexops
[10]:https://github.com/tiawl/spaceporn/blob/trunk/src/spaceporn/bindings/glfw/glfw.zig
