# coding: utf-8
require 'open-uri'
require 'stringio'
require 'uri'
require 'zipruby'
require 'haml'
require 'sinatra'
require 'nokogiri'
require './lib/aozora4reader'

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def base_url
    default_port = (request.scheme == "http") ? 80 : 443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    "#{request.scheme}://#{request.host}#{port}"
  end
end

configure do
  enable :sessions
end

get '/' do
  haml :index
end

get '/azr' do
  url = params[:url]
  unless url =~ /\.zip$/i
    # zipファイルの相対パスを取得
    zip_url = Nokogiri::HTML(open(url))
      .css('a')
      .map{|a| a.attr('href')}
      .find(proc{raise "zip file not found"}){|href| href =~ /\.zip$/i}
    url = URI.join(url, zip_url)
  end

  input = ''
  open(url) do |zipFile|
    Zip::Archive.open_buffer(zipFile.read) do |ar|
      ar.fopen(ar.get_name(0)) do |file|
        input = file.read
      end
    end
  end

  StringIO.open(input.encode("utf-8", "sjis"), "r") do |input|
    Aozora4Reader.a4r(input)
  end
end


