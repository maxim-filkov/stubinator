require 'sinatra/base'
require 'addressable/uri'

class Stubinator < Sinatra::Base
  before do
    @my_stubs = []
    Dir.glob('responses/*.json') do |path|
      stub = JSON.parse(File.read(path))
      @my_stubs << stub
    end
  end

  post '/stub' do
    begin
      body = request.body.read
      json = JSON.parse(body)
      if json['name'].nil? || json['request_path'].nil? || json['request_method'].nil?
        field =
          if json['name'].nil?
            'name'
          else
            json['request_path'].nil? ? 'request_path' : 'request_method'
          end
        response_with(400, "{\"error\":\"the '#{field}' field is required\"}")
      else
        add_stub('name' => json['name'],
                 'request_path' => json['request_path'],
                 'request_method' => json['request_method'],
                 'response_status' => json['response_status'].nil? ? 200 : json['response_status'],
                 'response_body' => json['response_body'].nil? ? '' : json['response_body'],
                 'response_headers' => json['response_headers'].nil? ? {} : json['response_headers'],
                 'request_body' => json['request_body'].nil? ? [] : json['request_body'])
        body ''
      end
    rescue JSON::ParserError
      response_with(400, '{"error":"the body should represent a stub in valid JSON format"}')
    end
  end

  delete '/stub' do
    begin
      json = JSON.parse(request.body.read)
      if json['name'].nil?
        response_with(400, '{"error":"the \'name\' field is required"}')
      else
        File.delete("responses/#{json['name']}.json")
      end
    rescue JSON::ParserError
      response_with(400, '{"error":"the body should represent a stub in valid JSON format"}')
    end
  end

  patch '/stub' do
    begin
      update = JSON.parse(request.body.read)
      if update['name'].nil?
        response_with(400, '{"error":"the \'name\' field is required"}')
      elsif File.exist?("responses/#{update['name']}.json")
        stub = JSON.parse(File.read("responses/#{update['name']}.json"))
        begin
          stub_json = JSON.parse(stub['response_body'])
          body_json = JSON.parse(update['response_body'])
        rescue StandardError
          # ignored
        end
        stub['response_headers'] = update['response_headers'].merge(update['response_headers']) unless update['response_headers'].nil?
        stub['response_status'] = update['response_status'] unless update['response_status'].nil?
        stub['response_body'] = stub_json.nil? && body_json.nil? ? update['response_body'] : stub_json.merge(body_json).to_json unless update['response_body'].nil?
        stub['request_path'] = update['request_path'] unless update['request_path'].nil?
        stub['request_method'] = update['request_method'] unless update['request_method'].nil?
        stub['request_body'] = update['request_body'] unless update['request_body'].nil?
        add_stub(stub)
        body ''
      else
        response_with(400, "{\"error\": \"stub with name '#{update['name']}' not found\"}")
      end
    rescue JSON::ParserError
      response_with(400, '{"error":"the body should represent a stub in valid JSON format"}')
    end
  end

  head '/*' do
    route('head', params)
  end

  get '/*' do
    route('get', params)
  end

  post '/*' do
    route('post', params)
  end

  put '/*' do
    route('put', params)
  end

  patch '/*' do
    route('patch', params)
  end

  delete '/*' do
    route('delete', params)
  end

  options '/*' do
    route('options', params)
  end

  private

  def add_stub(stub)
    @my_stubs.delete_if { |r| r['name'] == stub['name'] }
    @my_stubs << stub
    File.write("responses/#{stub['name']}.json", JSON.pretty_generate(stub))
  end

  def route(request_method, request_params)
    request_path = request_params[:splat].first
    request_body = request.body.read
    request_params.delete(:splat)
    request_params.delete(request_body.to_s) # this is for tests which send body as a part of params...
    request_params = request_params == {} ? nil : request_params

    route = @my_stubs.find do |stub|
      stub['request_path'].split('?').first == "/#{request_path}" &&
        request_method == stub['request_method'] &&
        request_params == Addressable::URI.parse(stub['request_path']).query_values &&
        (stub['request_body'].nil? ||
          stub['request_body'].count { |rb| /#{rb}/m.match(request_body) } == stub['request_body'].length)
    end

    if route.nil?
      response_with(404, "{\"error\": \"the stub '#{request_method.upcase!} /#{request_path}' hasn't been found\"}")
    else
      status route['response_status']
      route['response_headers'].each { |k, v| headers[k] = v }
      body route['response_body']
    end
  end

  def response_with(status, message)
    status status
    headers['Content-Type'] = 'application/json'
    body message
  end
end
