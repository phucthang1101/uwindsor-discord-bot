// The say command tells the bot to say something in a specified channel.
// For example, say #general hello world will have the bot say "hello world" in #general.
// Usage: say #<channel> <message>

import {logger} from "../logger";
import {BotModes, CommandType} from "../types";
import {SlashCommandBuilder} from "@discordjs/builders";
import {CommandInteraction, CacheType} from "discord.js";
import {ChannelType} from "discord-api-types";
import {Config} from "../config";

// TODO: permissions
const sayModule: CommandType = {
  data: new SlashCommandBuilder()
    .setName("say")
    .setDescription("Say something in a channel.")
    .addChannelOption((op) =>
      op
        .setName("channel")
        .setDescription("Where should the bot send your message?")
        .setRequired(true)
        .addChannelType(ChannelType.GuildText)
    )
    .addStringOption((op) =>
      op
        .setName("message")
        .setDescription("What do you want to say?")
        .setRequired(true)
    ),

  execute: async (interaction: CommandInteraction<CacheType>) => {
    let channelOption = interaction.options.getChannel("channel");
    let messageOption = interaction.options.getString("message");

    // if either of these cases are met, we should not reply. Instead, the command will time out
    // and show an error (which is preferable, at least in Isaac's opinion)
    if (channelOption === null || channelOption.type !== "GUILD_TEXT") {
      logger.info("Somehow got an invalid/null channel in the /say command.");
      return;
    } else if (messageOption === null) {
      logger.info("Somehow got a null message in the /say command.");
      return;
    }

    if (Config?.mode == BotModes.development) {
      logger.info(
        `${interaction.user} requested \'${messageOption}\' to be sent in #\'${channelOption.name}\'`
      );
    }
    channelOption.send(messageOption);
    await interaction.reply("Sent!");
  },
};

export {sayModule as command};
