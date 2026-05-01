# glfw.zig-0.15.2

This is a fork of [tiawl/glfw][0] which is itself a fork of [hexops/glfw][1] which is a fork of [glfw/glfw][2].

## How to use it

The goal of this repository is not to provide a [Zig][3] binding for [glfw/glfw][2]. There are at least as many legit ways as possible to make a binding as there are active accounts on Github. So you are not going to find an answer for this question here. The point of this repository is to abstract the [glfw/glfw][2] compilation process with [Zig][3] (which is not new comers friendly and not easy to maintain) to let you focus on your application. So you can use **glfw.zig**:
- as raw (see GLFW examples [here](https://github.com/tiawl/cimgui.zig/blob/trunk/examples)),

## Dependencies

The [Zig][3] part of this package is relying on the [Zig][3] release (0.15.2) and will only be.

Here the repositories' version used by this fork:
* [glfw/glfw](https://github.com/tiawl/glfw.zig/blob/trunk/.references/glfw)

[0]:https://github.com/tiawl/glfw.zig
[1]:https://github.com/hexops/glfw
[2]:https://github.com/glfw/glfw
[3]:https://github.com/ziglang/zig
