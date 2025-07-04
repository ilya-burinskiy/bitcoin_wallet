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
end
