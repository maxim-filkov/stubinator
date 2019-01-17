require 'sinatra/base'
require 'addressable/uri'

class Stubinator < Sinatra::Base
  before do
    @my_routes = []
    Dir.glob('responses/*.json') do |path|
      stub = JSON.parse(File.read(path))
      @my_routes << stub
    end
  end

  post '/numbers' do
    phone_data = JSON.parse(File.read('legacy_responses/phone.json'))
    phone_data['phone_number'] = "+1#{phone_data['area_code']}#{rand.to_s[4..10]}"
    status 200
    phone_data.to_json
  end

  post '/stub' do
    begin
      body = request.body.read
      json = JSON.parse(body)
      if json['name'].nil? || json['path'].nil? || json['method'].nil?
        field =
          if json['name'].nil?
            'name'
          else
            json['path'].nil? ? 'path' : 'method'
          end
        response_with(400, "{\"error\":\"the '#{field}' field is required\"}")
      else
        add_stub('name' => json['name'], 'path' => json['path'], 'method' => json['method'],
                 'status' => json['status'], 'body' => json['body'], 'headers' => json['headers'])
        body ''
      end
    rescue JSON::ParserError
      response_with(400, '{"error":"the body should represent a stub in valid JSON format"}')
    end
  end

  delete '/stub' do
    json = {}
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
          stub_json = JSON.parse(stub['body'])
          body_json = JSON.parse(update['body'])
        rescue StandardError
          # ignored
        end
        stub['headers'] = update['headers'].merge(update['headers']) unless update['headers'].nil?
        stub['status'] = update['status'] unless update['status'].nil?
        stub['path'] = update['path'] unless update['path'].nil?
        stub['method'] = update['method'] unless update['method'].nil?
        stub['body'] = stub_json.nil? && body_json.nil? ? update['body'] : stub_json.merge(body_json).to_json unless update['body'].nil?
        add_stub(stub)
        body ''
      else
        response_with(400, "{\"error\": \"stub with name '#{json['name']}' not found\"}")
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
    @my_routes.delete_if { |r| r['name'] == stub['name'] }
    @my_routes << stub
    File.write("responses/#{stub['name']}.json", stub.to_json)
  end

  def route(method, params)
    path = params[:splat].first
    params.delete(:splat)
    params = params == {} ? nil : params
    route = @my_routes.select { |r| r['path'].index("/#{path}") == 0 && r['method'] == method && params == Addressable::URI.parse(r['path']).query_values }.first
    if route.nil?
      response_with(404, "{\"error\": \"the stub '#{method.upcase!} /#{path}' hasn't been found\"}")
    else
      status route['status']
      route['headers'].each { |k, v| headers[k] = v }
      body route['body']
    end
  end

  def response_with(status, message)
    status status
    headers['Content-Type'] = 'application/json'
    body message
  end
end
