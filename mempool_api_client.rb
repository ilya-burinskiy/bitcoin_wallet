# frozen_string_literal: true
require 'net/http'
require 'json'

module MempoolApiClient
  def self.get_utxo(addr)
    JSON.parse(
      Net::HTTP.get(URI("https://mempool.space/signet/api/address/#{addr}/utxo")),
      symbolize_names: true
    )
  end

  def self.get_transaction(txid)
    JSON.parse(
      Net::HTTP.get(URI("https://mempool.space/signet/api/tx/#{txid}")),
      symbolize_names: true
    )
  end

  def self.create_tx(payload)
    uri = URI('https://mempool.space/signet/api/tx') 
    req = Net::HTTP::Post.new(uri)
    req.body = payload
    res = Net::HTTP.start(uri.hostname) do |http|
      http.request(req)
    end

    res.body
  end
end
