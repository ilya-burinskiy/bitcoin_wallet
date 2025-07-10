require 'bitcoin'

require_relative 'mempool_api_client'

COMISSION_SATOSHIES = 1000

Bitcoin.chain_params = :testnet

module Cmd
  def self.create
    privkey = SecureRandom.hex(32)
    File.open('private_key', 'wx') do |f|
      f.write(privkey)
    end
  rescue Errno::EEXIST
    puts 'Private key exist'
  end

  def self.get_balance
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

  def self.satoshi2btc(satoshi)
    satoshi * 1e-8
  end

  def self.btc2satoshi(btc)
    (btc * 1e8).to_i
  end

  def self.send_(to_addr, btc_amount)
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
    btc_key = Bitcoin::Key.new(priv_key: privkey)
    from_addr_confirmed_utxos.each_with_index do |utxo_attrs|
      txid = utxo_attrs[:txid]
      vout_idx = utxo_attrs[:vout]
      tx.in << Bitcoin::TxIn.new(out_point: Bitcoin::OutPoint.from_txid(txid, vout_idx))
    end

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

    from_addr_confirmed_utxos.each_with_index do |utxo_attrs, input_idx|
      txid = utxo_attrs[:txid]
      vout_idx = utxo_attrs[:vout]
      utxo = MempoolApiClient.get_transaction(txid)
      script_pubkey = Bitcoin::Script.parse_from_payload(utxo[:vout][vout_idx][:scriptpubkey].htb)
      sig_hash = tx.sighash_for_input(
        input_idx,
        script_pubkey,
        sig_version: :witness_v0,
        amount: utxo_attrs[:value]
      )
      signature = btc_key.sign(sig_hash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
      tx.in[input_idx].script_witness.stack << signature << btc_key.pubkey.htb
      unless tx.verify_input_sig(input_idx, script_pubkey, amount: utxo_attrs[:value])
        raise "input #{input_idx}: signature failed"
      end
    end

    raise 'invalid tx' unless tx.valid?

    payload = tx.to_hex
    puts MempoolApiClient.create_tx(payload)
  end
end