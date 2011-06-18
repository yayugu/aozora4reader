# coding: utf-8
require 'open-uri'
require 'stringio'
require 'zipruby'
require 'haml'
require 'sinatra'
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
  input = ''
  open(params[:url]) do |zipFile|
    Zip::Archive.open_buffer(zipFile.read) do |ar|
      ar.fopen(ar.get_name(0)) do |file|
        input = file.read  
      end
    end
  end

  StringIO.open(input, "r:SJIS") do |input|
    Aozora4Reader.a4r(input)
  end
end


