require 'bitcoin'
require 'optparse'

require_relative 'mempool_api_client'

COMISSION_SATOSHIES = 1000

Bitcoin.chain_params = :testnet

def create
  privkey = SecureRandom.hex(32)
  File.open('private_key', 'wx') do |f|
    f.write(privkey)
  end
rescue Errno::EEXIST
  puts 'Private key exist'
end

def get_balance
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
  -1
end

def satoshi2btc(satoshi)
  satoshi * 1e-8
end

def btc2satoshi(btc)
  (btc * 1e8).to_i
end

def send_(to_addr, btc_amount)
  privkey = File.open('private_key', 'r') { |f| f.read }
  from_addr = Bitcoin::Descriptor::Wpkh
    .new(Bitcoin::Secp256k1::Ruby.generate_pubkey(privkey))
    .to_script
    .to_addr
  from_addr_confirmed_utxos = MempoolApiClient
    .get_utxo(from_addr)
    .filter { |utxo| utxo[:status][:confirmed] }
  from_addr_satoshies = from_addr_confirmed_utxos.reduce(0) { |sum, utxo| sum + utxo[:value] }

  to_addr_satoshies = btc2satoshi(btc_amount)
  if from_addr_satoshies < to_addr_satoshies + COMISSION_SATOSHIES
    puts 'Not enough coins'
    return
  end

  tx = Bitcoin::Tx.new
  tx.out << Bitcoin::TxOut.new(
    value: to_addr_satoshies,
    script_pubkey: Bitcoin::Script.parse_from_addr(to_addr)
  )
  change = from_addr_satoshies - to_addr_satoshies - COMISSION_SATOSHIES
  if change != 0
    tx.out << Bitcoin::TxOut.new(
      value: change,
      script_pubkey: Bitcoin::Script.parse_from_addr(from_addr)
    )
  end

  btc_key = Bitcoin::Key.new(priv_key: privkey)
  from_addr_confirmed_utxos
    .map { |utxo_attrs| MempoolApiClient.get_transaction(utxo_attrs[:txid]) }
    .each_with_index do |utxo, input_idx|
      utxo[:vout]
        .each_with_index
        .filter { |vout, idx| vout[:scriptpubkey_address] == from_addr }
        .map { |_vout, idx| idx }
        .each do |vout_idx|
          tx.in << Bitcoin::TxIn.new(out_point: Bitcoin::OutPoint.from_txid(utxo[:txid], vout_idx))
          script_pubkey = Bitcoin::Script.parse_from_payload(
            utxo[:vout][vout_idx][:scriptpubkey].htb
          )
          sig_hash = tx.sighash_for_input(
            input_idx,
            script_pubkey,
            sig_version: :witness_v0,
            amount: utxo[:vout][vout_idx][:value]
          )
          signature = btc_key.sign(sig_hash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
          tx.in[input_idx].script_witness.stack << signature << btc_key.pubkey.htb
          unless tx.verify_input_sig(input_idx, script_pubkey, amount: utxo[:vout][vout_idx][:value])
            raise "input_idx=#{input_idx} signature failed"
          end
        end
  end
  debugger
  raise 'Invalid tx' unless tx.valid?

  payload = tx.to_hex
  puts payload
  puts MempoolApiClient.create_tx(payload)
end

# TODO: нормально парсить аргументы
if ARGV.length == 0
  puts 'Enter one of this commands: create, balance, send'
  exit
end

case ARGV[0]
when 'create' then create
when 'balance'
  balance = get_balance
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
    # TODO: валидировть число и адрес
    send_(receiver_addr, btc_amount.to_f)
  else
    puts 'Missing BTC amount' if btc_amount.nil?
    puts 'Missing receiver address' if receiver_addr.nil?
  end
else
  puts 'Enter one of this commands: create, balance, send'
end
