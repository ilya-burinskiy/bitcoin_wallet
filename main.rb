require 'bitcoin'
require 'digest'
require 'optparse'

require_relative 'mempool_api_client'

COMISSION_SATOSHIES = 1000

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

def btc2satoshi(btc)
  (btc * 1e8).to_i
end

def send_(receiver_addr, btc_amount)
  privkey = File.open('private_key', 'r') { |f| f.read }
  pubkey = Bitcoin::Secp256k1::Ruby.generate_pubkey(privkey)
  wpkh = Bitcoin::Descriptor::Wpkh.new(pubkey)
  addr = wpkh.to_script.to_addr
  confirmed_utxos =  MempoolApiClient
    .get_utxo(addr)
    .filter { |utx| utx[:status][:confirmed] }
  satoshies_balance = confirmed_utxos.reduce(0) { |sum, utx| sum + utx[:value] }

  satoshies_amount = btc2satoshi(btc_amount) + CO
  if satoshies_balance < btc2satoshi(btc_amount) + COMISSION_SATOSHIES
    puts 'Not enough coins'
    return
  end

  my_vouts = confirmed_utxos.each_with_object({}) do |utxo, h|
    tx = MempoolApiClient.get_transaction(utxo[:txid])
    h[utxo[:txid]] = tx[:vout].filter { |vout| vout[:scriptpubkey_address] == addr }
  end

  puts my_vouts
  puts "Sending #{btc_amount} to #{receiver_addr}"
end

# TODO: нормально парсить аргументы
if ARGV.length == 0
  puts 'Enter one of this commands: create, balance, send'
  exit
end

case ARGV[0]
when 'create' then create
when 'balance' then puts "Balance: #{balance} BTC"
when 'send'
  btc_amount = nil
  receiver_addr = nil
  OptionParser.new do |opts|
    opts.banner = 'Usage: main.rb send [OPTIONS]'
    opts.on('--addr ADDR', 'Address') { |val| receiver_addr = val }
    opts.on('--amount AMOUNT', 'Amount. Example 0.0001') { |val| btc_amount = val }
  end.parse!

  if !btc_amount.nil? && !receiver_addr.nil?
    # TODO: валидировть число и адрес
    send_(receiver_addr, btc_amount.to_f)
  else
    puts 'Missing BTC amount' if btc_amount.nil?
    puts 'Missing receiver address' if receiver_addr.nil?
  end
else
  puts 'Enter one of this commands: create, balance, send'
end
