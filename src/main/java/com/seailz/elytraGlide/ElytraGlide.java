package com.seailz.elytraGlide;

import com.comphenix.protocol.PacketType;
import com.comphenix.protocol.ProtocolLibrary;
import com.comphenix.protocol.ProtocolManager;
import com.comphenix.protocol.events.PacketAdapter;
import com.comphenix.protocol.events.PacketEvent;
import com.comphenix.protocol.events.ListenerPriority;
import com.mojang.brigadier.arguments.FloatArgumentType;
import io.papermc.paper.command.brigadier.Commands;
import io.papermc.paper.plugin.lifecycle.event.types.LifecycleEvents;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public final class ElytraGlide extends JavaPlugin {

    private static ElytraGlide instance;

    private static final long BASE_TICKS = 12000;
    private static final int MAX_SIGNAL_TICKS = 400;

    private ProtocolManager protocolManager;

    // Store per-player desired gameTime value (in ticks)
    private final Map<UUID, Long> desiredGameTime = new ConcurrentHashMap<>();

    @Override
    public void onEnable() {
        instance = this;
        protocolManager = ProtocolLibrary.getProtocolManager();

        // Intercept ALL outgoing UPDATE_TIME packets and overwrite gameTime for controlled players
        protocolManager.addPacketListener(new PacketAdapter(
                this,
                ListenerPriority.HIGHEST,
                PacketType.Play.Server.UPDATE_TIME
        ) {
            @Override
            public void onPacketSending(PacketEvent event) {
                Player p = event.getPlayer();
                Long fakeGameTime = desiredGameTime.get(p.getUniqueId());
                if (fakeGameTime == null) return;

                // Only overwrite the gameTime field (index 0).
                event.getPacket().getLongs().write(0, fakeGameTime);
                event.getPacket().getLongs().write(1, 0L);

                 // send our own packet again to double the amount of packets sent
                Bukkit.getScheduler().runTaskLater(instance, () -> {
                    try {
                        protocolManager.sendServerPacket(p, event.getPacket());
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }, 5L);
            }
        });

        // Register /angle <degrees>
        this.getLifecycleManager().registerEventHandler(LifecycleEvents.COMMANDS, commands -> {
            commands.registrar().register(
                    Commands.literal("angle")
                            .then(Commands.argument("degrees", FloatArgumentType.floatArg(-90f, 90f))
                                    .executes(ctx -> {
                                        float degrees = ctx.getArgument("degrees", Float.class);

                                        long offsetTicks = Math.round((degrees / 90.0f) * MAX_SIGNAL_TICKS);
                                        long quant = 10; // Quantize to fix the effect where the game keeps counting up and then snaps back on a packet
                                        long fakeGame = BASE_TICKS + offsetTicks;

                                        fakeGame = (fakeGame / quant) * quant;

                                        Player player = (Player) ctx.getSource().getSender();
                                        desiredGameTime.put(player.getUniqueId(), fakeGame);

                                        player.sendMessage("Angle=" + degrees + " -> fakeGameTime=" + fakeGame);
                                        return 1;
                                    })
                            )
                            // Optional: /angle off
                            .then(Commands.literal("off").executes(ctx -> {
                                Player player = (Player) ctx.getSource().getSender();
                                desiredGameTime.remove(player.getUniqueId());
                                player.sendMessage("Angle override disabled");
                                return 1;
                            }))
                            .build()
            );
        });
    }

    @Override
    public void onDisable() {
        desiredGameTime.clear();
        if (protocolManager != null) protocolManager.removePacketListeners(this);
    }
}
