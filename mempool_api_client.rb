# frozen_string_literal: true
require 'net/http'

module MempoolApiClient
  def self.get_utxo(addr)
    Net::HTTP.get(URI("https://mempool.space/signet/api/address/#{addr}/utxo"))
  end
end
