# glfw.zig

This is a fork of [hexops/glfw][1] which is itself a fork of [glfw/glfw][2].

## Why this forkception ?

The intention under this fork is the same as [hexops][4] had when they forked [glfw/glfw][2]: package it for [Zig][3]. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`.

However this repository has subtle differences for maintainability tasks:
* No shell scripting,
* A cron runs every day to check [glfw/glfw][2] and other dependencies. Then it updates this repository if a new release is available.

## How to use it

The goal of this repository is not to provide a [Zig][3] binding for [glfw/glfw][2]. The point of this repository is to abstract the [glfw/glfw][2] compilation process with [Zig][3] (which is not easy to maintain) to let you focus on your application. So you can use **glfw.zig**:
- as raw (see GLFW examples [here](https://github.com/tiawl/cimgui.zig/blob/stable/examples)),
- as a daily updated interface for your [Zig][3] binding of [glfw/glfw][2]

## Dependencies

The [Zig][3] part of this package requires the latest (0.16.0) or the master (0.17.0-dev) [Zig][3] release.

For other dependencies see [the build.zig.zon](https://github.com/tiawl/glfw.zig/blob/stable/build.zig.zon)

## `zig build` options

These additional options have mainly been implemented for maintainability tasks but they maybe could be useful for edge usecases:
```
  -Dfetch   Update build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

This repository is not subject to a unique License:

The parts of this repository originated from this repository are dedicated to the public domain. See the LICENSE file for more details.

**For other parts, it is subject to the License restrictions their respective owners choosed. By design, the public domain code is incompatible with the License notion. In this case, the License prevails. So if you have any doubt about a file property, open an issue.**

[1]:https://github.com/hexops/glfw
[2]:https://github.com/glfw/glfw
[3]:https://codeberg.org/ziglang/zig
[4]:https://github.com/hexops
