# -*- coding: UTF-8 -*-

# just run this ruby script; no special parameters. a config.yml file in the same
# directory should look like this:
#
# discord:
#   token: 'a discord api token goes here'
#   client_id: 'a discord client id goes here'
#
# Other than that, set up the bot so it has role permissions to assign and
# remove roles. This bot is written to watch reactions to posts made to a
# channel named '#assignment'. If a reaction is added or removed from a post
# the bot will scan the content of the post for any line that contains that
# same reaction and a role name mention. If it finds one, it will add or
# remove the role, depending on whether the reaction was added or removed.

require 'discordrb'
require 'yaml'

#cnf = YAML::load_file(File.join(__dir__, 'config.yml'))

bot = Discordrb::Bot.new token: ENV['bot_token'], client_id: ENV['bot_clientid']

def assign_role_by_reaction(event, &block)
  if event.channel.name == 'role-assignment' || event.channel.name == 'rules-and-info'
    # check for role_mentions... if we have some, then this is actionable
    if not event.message.role_mentions.empty?
      message_lines = event.message.content.lines
      message_lines.keep_if { | line | line.include?(event.emoji.name) and line =~ /<@&[0-9]+>/ }
      if not message_lines.empty?
        m = message_lines[0].match(/<@&([0-9]+)>/)
        if m
          role = event.message.role_mentions.select { | r | r.id.to_s == m[1] }
          if not role.empty?
            block.call event.channel.server.member(event.user.id), role[0]
          end
        end
      end
    end
  end
  #if event.channel.name == 'rules-and-info'
   # if event.emoji.name == ':thumbsup:'
   # role = event.message.role_mentions.select { | r | r.id.to_s == 'Pink' }
   #   block.call event.channel.server.member(event.user.id), role[0]
   # end
  #end
end

bot.reaction_add do |event|
  assign_role_by_reaction(event) do | member, role |
    if not member.role?(role)
      member.add_role(role)
    end
  end
end

bot.reaction_remove do |event|
  assign_role_by_reaction(event) do | member, role |
    if member.role?(role)
      member.remove_role(role)
    end
  end
end

bot.run
