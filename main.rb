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
  privkey = File.open('private_key', 'r') { |f| f.read }
  pubkey = Bitcoin::Secp256k1::Ruby.generate_pubkey(privkey)
  wpkh = Bitcoin::Descriptor::Wpkh.new(pubkey)
  addr = wpkh.to_script.to_addr
  utxos =  MempoolApiClient.get_utxo(addr)
  satoshies = utxos
    .filter { |utx| utx[:status][:confirmed] }
    .reduce(0) { |tot_amount, utx| tot_amount + utx[:value] }
  satoshi2btc(satoshies)
rescue Errno::ENOENT
  puts 'No private key'
end

def satoshi2btc(satoshi)
  satoshi * 1e-8
end

# TODO: нормально парсить аргументы
if ARGV.length == 0
  puts 'Enter one of this commands: create, balance, send'
  exit
end

case ARGV[0]
when 'create' then create
when 'balance' then puts "Balance: #{balance} BTC"
else
  puts 'Enter one of this commands: create, balance, send'
end
