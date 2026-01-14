package com.seailz.flaps;

import com.comphenix.protocol.ProtocolLibrary;
import io.papermc.paper.command.brigadier.Commands;
import io.papermc.paper.plugin.lifecycle.event.types.LifecycleEvents;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.TextComponent;
import net.kyori.adventure.text.event.ClickEvent;
import net.kyori.adventure.text.event.HoverEvent;
import net.kyori.adventure.text.format.NamedTextColor;
import net.kyori.adventure.text.format.TextDecoration;
import org.bukkit.plugin.java.JavaPlugin;

public class FlapsPlugin extends JavaPlugin {

    private static final String VERSION = "1.0.0";


    @Override
    public void onLoad() {
        Flaps flp = new Flaps(this,  ProtocolLibrary.getProtocolManager(), true);
        flp.start();
    }

    @Override
    public void onEnable() {
        super.onEnable();

        getLifecycleManager().registerEventHandler(LifecycleEvents.COMMANDS, commands -> {
            commands.registrar().register(
                    Commands.literal("flaps").executes(ctx -> {

                        TextComponent header = Component.text()
                                .append(Component.text("✔ ", NamedTextColor.GREEN))
                                .append(Component.text("Flaps", NamedTextColor.GREEN).decorate(TextDecoration.BOLD))
                                .append(Component.text(" v" + VERSION, NamedTextColor.GRAY))
                                .build();

                        TextComponent creator = Component.text()
                                .append(
                                        Component.text("https://github.com/seailz/flaps", NamedTextColor.GRAY)
                                                .clickEvent(ClickEvent.openUrl("https:///github.com/seailz/flaps"))
                                                .hoverEvent(HoverEvent.showText(Component.text("Click to open", NamedTextColor.GRAY)))
                                )
                                .build();


                        ctx.getSource().getSender().sendMessage(header);
                        ctx.getSource().getSender().sendMessage(creator);

                        return 1;
                    }).build());
        });
    }

    @Override
    public void onDisable() {
        super.onDisable();
    }
}
