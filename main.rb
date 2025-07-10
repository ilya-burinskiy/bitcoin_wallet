require 'optparse'
require_relative 'cmd'

if ARGV.length == 0
  puts 'Enter one of this commands: create, balance, send'
  exit
end

case ARGV[0]
when 'create' then Cmd.create
when 'balance'
  balance = Cmd.get_balance
  if balance >= 0
    puts "Balance: #{balance} BTC"
  end
when 'send'
  btc_amount = nil
  receiver_addr = nil
  OptionParser.new do |opts|
    opts.banner = 'Usage: main.rb send [OPTIONS]'
    opts.on('--addr ADDR', 'Address') { |val| receiver_addr = val }
    opts.on('--amount AMOUNT', 'Amount. Example 0.0001') { |val| btc_amount = val }
  end.parse!

  if !btc_amount.nil? && !receiver_addr.nil?
    Cmd.send_(receiver_addr, btc_amount.to_f)
  else
    puts 'Missing BTC amount' if btc_amount.nil?
    puts 'Missing receiver address' if receiver_addr.nil?
  end
else
  puts 'Enter one of this commands: create, balance, send'
end
