require 'slack-ruby-client'
require 'date'
require_relative 'slack_facts'

USER_JOSH   = 'U7LT1NL7R'
USER_SEAN   = 'U7LUMFQE6'

TOKEN       = SlackFacts::KEYS[:STRANGE_BIRD]

OUTPUT_FILE = 'strange_bird_output.txt'

Slack.configure do |config|
  config.token = TOKEN
end

client = Slack::RealTime::Client.new

def make_hash (things_to_hash_up, name_of_name_field)
  return_hash = {}
  things_to_hash_up.each do |thing|
    if thing[name_of_name_field] != nil
      return_hash[thing['id']] = thing[name_of_name_field]
    end
  end
  return_hash
end

users     = client.web_client.users_list.members
channels  = client.web_client.channels_list.channels
groups    = client.web_client.groups_list.groups
ims       = client.web_client.im_list.ims

users_hash    = make_hash users, 'real_name'
channels_hash = make_hash channels, 'name'
groups_hash   = make_hash groups, 'name'
ims_hash      = make_hash ims, 'user'

ims_hash.update(ims_hash) do |im, user|
  users_hash[user]
end

channels_hash.merge!(groups_hash)
channels_hash.merge!(ims_hash)

client.on :hello do
  File.open(OUTPUT_FILE, 'a') { |file|
    file.write("-------------------------------------------\n")
    file.write("Successfully logged in at #{Time.now.strftime('%_I:%M:%S %p')}\n")
  }
end

client.on :message do |data|
  user_id     = data['user']
  channel_id  = data['channel']
  content     = data['text']
  timestamp   = timestamp = DateTime.strptime((data['ts'].to_i*1000).to_s, '%Q').new_offset('-5:00')

  File.open(OUTPUT_FILE, 'a') { |file|
    file.write("-------------------------------------------\n")
    file.write("Username: #{users_hash[user_id]}\n")
    file.write("Channel name: #{channels_hash[channel_id]}\n")
    file.write("Content: #{content}\n")
    file.write("Timestamp: #{timestamp.strftime('%_I:%M:%S %p').strip}\n")
  }

  case data['text']
  when /cold/ then
    File.open(OUTPUT_FILE, 'a') { |file|
      file.write("let these fuckers know just how cold it was\n")
    }
    client.message channel: channel_id, text: "i was FREOZEN, TODAY!!!"

  when /terrorism/ then
   File.open(OUTPUT_FILE, 'a') { |file|
    file.write("die a happy man\n")
   }
   client.message channel: channel_id, text: "Gentlemen, I can categorically say that today I could die as a result of a terrorist attack, and be going out on a  high note."
  end
end

client.start!
