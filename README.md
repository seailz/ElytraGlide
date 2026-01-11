# ElytraGlide
Proof of concept experimenting with communicating with resource pack shaders from a server-side plugin by using the `GameTime` property that can be accessed in shaders and controlled by packets.
<br><BR>If successful, this project would demonstrate an ability to control shader effects on clients from the server side, opening up possibilities for dynamic visual effects in Minecraft, notably recreating the [roll effect when turning](https://www.youtube.com/watch?v=4TVhD3RRQrc) using an Elytra on the Legacy console editions. However,
with essentially unlimited access to the shader code, the possibilities are much broader than just this specific effect.
<br><br>As this project relies on modifying [core shaders](https://minecraft.wiki/w/Shader#Core-shaders), it is highly experimental and not officially supported by Mojang.

## Overview
The plugin works by sending packets to clients to modify the `GameTime` property, which is then read by custom shaders in a resource pack. The current iteration sets an agreed upon time value (6000 ticks), which is then offset by a value to control the angle of the glide effect, which can be detected by the shader.
