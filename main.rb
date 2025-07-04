require 'bitcoin'
require 'optparse'

Bitcoin.chain_params = :testnet

def create
  entropy = SecureRandom.hex(16)
  mnemonic = Bitcoin::Mnemonic.new('english')
  word_list = mnemonic.to_mnemonic(entropy) # 12 слов
  puts "Please remember this words #{word_list}"
  seed = mnemonic.to_seed(word_list)
  master_key = Bitcoin::ExtKey.generate_master(seed)

  key = master_key
    .derive(84, true)
    .derive(0, true)
    .derive(0, true)
    .derive(0)
    .derive(0)

  File.open('private_key', 'wx') do |f|
    f.write(key.to_base58)
  rescue Errno::EEXIST
    puts 'You already have wallet'
  end

  puts "Your address is #{key.addr}"
end

def restore
  File.open('private_key', 'r') do |f|
    ext_privkey = Bitcoin::ExtKey.from_base58(f.read)
  rescue Errno::ENOENT
    puts 'Private key not found'
  end
  puts 'Private key restored'
end

# TODO: нормально парсить аргументы
if ARGV.length == 0
  puts 'Enter one of this commands: create, balance, send'
  exit
end

case ARGV[0]
when 'create' then create
when 'balance'
when 'send'
when 'restore' then restore
else
  puts 'Enter one of this commands: create, balance, send'
end
