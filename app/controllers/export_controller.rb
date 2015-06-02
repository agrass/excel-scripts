require 'oauth2'
require 'net/http'
require 'json'
require 'axlsx'

class ExportController < ApplicationController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception

  def list
    token = get_access_token(params)
    @orders = []
    orders = get_orders(token)
    orders.each do |order|
      order["_embedded"]["line_items"].each do |item|
        @orders << { :contact => order["_embedded"]["contact"]["name"], :name =>  item["product_title"], :variant => item["variant_title"], :units => item["requested_units"]}
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xls
      format.xml  { render :xml => @orders }
    end

  end

  def chilexpress
    token = get_access_token(params)
    @orders = []
    orders = get_orders(token)
    orders.each do |order|
      @orders << { 'data' => order, 'address' => process_address(order) }
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xls
      format.xml  { render :xml => @orders }
    end
  end
  def get_access_token(params)
    client = OAuth2::Client.new(
      ENV['BOOTIC_CLIENT_ID'],
      ENV['BOOTIC_CLIENT_SECRET'],
      site: "https://auth.bootic.net"
    )

    token = client.password.get_token(params[:BOOTIC_USER], params[:BOOTIC_PASS], auth_scheme: 'basic', scope: "admin").token
    return token
  end

  def get_orders(token)
    ur = "https://api.bootic.net/v1/shops/1491/orders.json"
    uri = URI.parse(ur)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Get.new(uri.path + "?status=closed", {'Authorization' =>"Bearer #{token}", "Content-Type" => "application/json", "status" => "closed"})
    res = https.request(req)
    items = JSON.parse(res.body.to_s)
    items = items["_embedded"]["items"]
  end

  def process_address(order)
    comuna = order["_embedded"]["address"]["locality_name"]
    calle_temp = order["_embedded"]["address"]["street"]
    referencia = order["_embedded"]["address"]["street_2"]
    street = [calle_temp, referencia].reject { |c| c.empty? }.join(", ")
    return street, comuna
  end


end
