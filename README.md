# Flaps
Flaps is a proof of concept experimenting with communicating with resource pack shaders from a server-side plugin by using the `GameTime` property that can be accessed in shaders and controlled by packets.
<br><BR>Flaps demonstrates an ability to control shader effects on clients from the server side, opening up possibilities for dynamic visual effects in Minecraft without mods, notably recreating the [roll effect when turning](https://www.youtube.com/watch?v=4TVhD3RRQrc) using an Elytra on the Legacy console editions. However, now with essentially unlimited access to the shader code, the possibilities are much broader than just this specific effect.

https://github.com/user-attachments/assets/a44e6dd3-57b6-4b8c-827c-51507e512070




https://github.com/user-attachments/assets/e8788e23-1c4f-442f-8dcf-b84a13499390





https://github.com/user-attachments/assets/5a02b76d-5fa1-49e9-8a17-aa0664a038f1



Potential use cases include:
- Dynamic visual weather effects (e.g., heat distortion during a heatwave)
- Visual effects tied to in-game events (e.g., screen distortion during earthquakes or explosions)
- Camera shake during horror scenes, boss fights, etc
- Dynamic day/night cycle effects (e.g., color grading during sunrise/sunset)
- Special effects for abilities or power-ups (e.g., motion blur when sprinting or speed boosts)

>As this project relies on modifying [core shaders](https://minecraft.wiki/w/Shader#Core-shaders), it is highly experimental and not officially supported by Mojang.

## Overview
The plugin works by sending packets to clients to modify the `GameTime` property, which is then read by custom shaders in a resource pack. The current iteration sets an agreed upon time value (12000 ticks), which is 
then quantized as the client keeps progressing GameTime unless reset by the server and not doing so would cause drift for a few seconds. We are then left with +/- 1200 possible states per tick (shaders are stateless). Unfortunately this is the current limiation and no more data can be embedded. It *may* be possible to extend this by removing quantization and instead sending packets every tick, at an increased bandwidth and risk of losing sync with the server. 

Flaps is currently configured and the resource pack is currently only designed for Java Edition 1.21.8. As core shaders are subject to change, it may not work on other versions without modification.

### Resource Pack
The resource pack overrides the core shaders (located in `assets/minecraft/shaders/core/`) to apply effects from a shared file (`assets/elytraglide/shaders/include/eg_effects_vertex.glsl`) based on the modified `GameTime` value from the server.

## How to use

There are two types of shaders: vertex shaders (`.vsh`) and fragment shaders (`.fsh`). Vertex shaders handle the geometry of objects (so are good for camera effects etc), while fragment shaders handle the coloring and texturing of pixels (useful for color grading, distortion effects, etc).

1. **Install the texture pack**: This can be found in the `resourcepack` folder of this repository. Either add it to your .minecraft or set it as your server's resource pack.
2. **Install the plugin**: Add the Flaps plugin jar file to your server's plugins folder.
3. **Modify the shader effects**:
    - Open the resource pack and navigate to `assets/elytraglide/shaders/include/eg_effects_vertex.glsl` if you're modifying vertex shaders
        - The function at the bottom of the file, `eg_apply_vertex_effects`, can be modified to create your own effects and apply them to the core shaders. There are a few presets which you can use as a starting point, or create your own logic.
    - If you want to modify fragment shaders instead, navigate to `assets/elytraglide/shaders/include/eg_effects_fragment.glsl` and modify the `eg_apply_fragment_effects` function.
    - The server modifies the `gameTime` variable found in both files, so you can use this variable to dynamically change/enable/disable effects from the server based on its value. In future versions of Flaps this'll be made easier by including an automatic encoding and decoding system.
    - Refer to the [Minecraft shader documentation](https://minecraft.wiki/w/Shader) for more information on shader programming. There is limited information available so you may need to experiment.
    - You can also modify the core shaders directly if you want to make substantial changes, but most effects should be possible through the include files.
4. **Modify the plugin**: Again, since there's no API or encoding system available yet, you will need to modify and compile the plugin yourself to change how the `GameTime` variable is set. An API will be added in future versions to make this easier.
    - If you'd prefer to do this yourself in your own plugin, use ProtocolLib (or NMS) to send a [`ClientboundUpdateTimePacket`](https://minecraft.wiki/w/Java_Edition_protocol/Packets#Update_Time) to clients every tick (or as often as needed) setting the first and second longs to your desired `GameTime` value, and the first boolean to `false`.
5. **Test your changes**: Start your server and join with a client that has the resource pack installed. Test the shader effects and make adjustments as needed.

## Known issues
The complexity of modifying core shaders and the fact that it's unsupported means you **will** encounter visual bugs. Some known issues include:
- Celestial bodies are not controlled by the shader (and can appear to duplicate in some cases)
- The day/night cycle is currently disabled
- Riding a boat can look weird
- Holding an item in F5 view can look weird
- Shaders cannot change the lower half of the sky. There is no solution to this. (notice how the snow particles are not visible within the blue area.)
  - <img width="3440" height="1417" alt="2026-01-13_14 19 47" src="https://github.com/user-attachments/assets/8c4b8b8c-f032-4b21-b097-aea95460d423" />

- The player's hand is considered an entity and will have effects applied to it
  - The only way of detecting the hand is to check the proximity to the camera, which can lead to false positives with real mobs/entities and cause strange effects
  - For most servers, particularly for temporary effects, it's recommended to allow the hand to be affected by the shader to prevent issues with entities
  - If you want to change this behavior, uncomment the if statement in the `entity.vsh` file in the resource pack
  - There is no solution to allow the hand to be unaffected while also preventing false positives with entities

### Particle effects
Particle effects could theoretically be used to communicate with shaders too. This has not been implemented by me in this project. [A similar project](https://github.com/HalbFettKaese/ShaderSelectorV3) does
use particles, but relies on the "Fabulous!" graphics setting (using a post-process shader) which is not widely used. This project modifies core shaders instead, which while less supported and more prone to bugs,
works on all graphics settings and for all players.
