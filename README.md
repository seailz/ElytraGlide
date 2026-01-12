# Flaps
Flaps is a proof of concept experimenting with communicating with resource pack shaders from a server-side plugin by using the `GameTime` property that can be accessed in shaders and controlled by packets.
<br><BR>Flaps demonstrates an ability to control shader effects on clients from the server side, opening up possibilities for dynamic visual effects in Minecraft without mods, notably recreating the [roll effect when turning](https://www.youtube.com/watch?v=4TVhD3RRQrc) using an Elytra on the Legacy console editions. However, now with essentially unlimited access to the shader code, the possibilities are much broader than just this specific effect.

https://github.com/user-attachments/assets/a44e6dd3-57b6-4b8c-827c-51507e512070

Potential use cases include:
- Dynamic visual weather effects (e.g., heat distortion during a heatwave)
- Visual effects tied to in-game events (e.g., screen distortion during earthquakes or explosions)
- Camera shake during horror scenes, boss fights, etc
- Dynamic day/night cycle effects (e.g., color grading during sunrise/sunset)
- Special effects for abilities or power-ups (e.g., motion blur when sprinting or speed boosts)

>As this project relies on modifying [core shaders](https://minecraft.wiki/w/Shader#Core-shaders), it is highly experimental and not officially supported by Mojang.

## Overview
The plugin works by sending packets to clients to modify the `GameTime` property, which is then read by custom shaders in a resource pack. The current iteration sets an agreed upon time value (12000 ticks), which is 
then quantized as the client keeps progressing GameTime unless reset by the server and not doing so would cause drift for a few seconds. We are then left with 1200, or, in other words, 4 integers that can be cmmunicated to the shader from the server. Unfortunately this is the current limiation and no more data can be embedded. It *may* be possible to extend this to 5 digits by removing quantization and instead sending packets every tick, at an increased bandwidth and risk of losing sync with the server. 

Flaps is currently configured and the resource pack is currently only designed for Java Edition 1.21.8. As core shaders are subject to change, it may not work on other versions without modification.

### Resource Pack
The resource pack overrides the core shaders (located in `assets/minecraft/shaders/core/`) to apply effects from a shared file (`assets/elytraglide/shaders/include/eg_effects_vertex.glsl`) based on the modified `GameTime` value from the server.

The effect can be customized in the `eg_effects_vertex.glsl` file. The current implementation applies a roll effect based on the offset limited at +/- 20 degrees. You should modify this file's logic
to create your own effects based on the `gameTimeOffset` variable.

## Known issues
The complexity of modifying core shaders and the fact that it's unsupported means you **will** encounter visual bugs. Some known issues include:
- Celestial bodies are not controlled by the shader
- The day/night cycle is currently disabled
- Riding a boat can look weird
- Holding an item in F5 view can look weird
- The player's hand is considered an entity and will have effects applied to it
  - The only way of detecting the hand is to check the proximity to the camera, which can lead to false positives with real mobs/entities and cause strange effects
  - For most servers, particularly for temporary effects, it's recommended to allow the hand to be affected by the shader to prevent issues with entities
  - If you want to change this behavior, uncomment the if statement in the `entity.vsh` file in the resource pack
  - There is no solution to allow the hand to be unaffected while also preventing false positives with entities

### Particle effects
Particle effects could theoretically be used to communicate with shaders too. This has not been implemented by me in this project. [A similar project](https://github.com/HalbFettKaese/ShaderSelectorV3) does
use particles, but relies on the "Fabulous!" graphics setting (using a post-process shader) which is not widely used. This project modifies core shaders instead, which while less supported and more prone to bugs,
works on all graphics settings and for all players.
