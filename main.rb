require 'bitcoin'
require 'digest'

require_relative 'mempool_api_client'

Bitcoin.chain_params = :testnet

def create
  privkey = SecureRandom.hex(128)
  File.open('private_key', 'wx') do |f|
    f.write(privkey)
  end
rescue Errno::EEXIST
  puts 'Private key exist'
end

def balance
  privkey = File.open('private_key', 'r') do |f|
    f.read
  end
  pubkey = Bitcoin::Secp256k1::Ruby.generate_pubkey(privkey)
  wpkh = Bitcoin::Descriptor::Wpkh.new(pubkey)
  addr = wpkh.to_script.to_addr
  puts MempoolApiClient.get_utxo(addr)
rescue Errno::ENOENT
  puts 'No private key'
end

# TODO: нормально парсить аргументы
if ARGV.length == 0
  puts 'Enter one of this commands: create, balance, send'
  exit
end

case ARGV[0]
when 'create' then create
when 'balance' then balance
else
  puts 'Enter one of this commands: create, balance, send'
end
