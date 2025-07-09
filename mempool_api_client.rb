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
    url = URI.parse('https://mempool.space/signet/api/tx') 
    req = Net::HTTP::Post.new(url)
    req.body = payload
    req.content_type = 'text/plain'
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      http.request(req)
    end

    res.body
  end
end
