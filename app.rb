require 'sinatra/base'

class Stubinator < Sinatra::Base

  @@my_routes = []

  before do
    Dir.glob("responses/*.json") { |path|
      stub = JSON.parse(File.read(path))
      @@my_routes << stub
    }
  end

  post '/stub' do
    begin
      body = request.body.read
      json = JSON.parse(body)
      if json['name'].nil? or json['path'].nil? or json['method'].nil?
        field = json['name'].nil? ? 'name' : json['path'].nil? ? 'path' : 'method'
        response_with(400, "{\"error\":\"the '#{field}' field is required\"}")
      else
        add_stub({ 'name' => json["name"], 'path' => json["path"], 'method' => json['method'],
                   'status' => json["status"], 'body' => json["body"], 'headers' => json["headers"] })
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
    update = {}
    begin
      update = JSON.parse(request.body.read)
      if update['name'].nil?
        response_with(400, '{"error":"the \'name\' field is required"}')
      else
        if File.exist?("responses/#{update['name']}.json")
          stub = JSON.parse(File.read("responses/#{update['name']}.json"))
          begin
            stub_body_as_json = JSON.parse(stub['body'])
            body_as_json = JSON.parse(update['body'])
          rescue Exception
            # ignored
          end
          unless update['headers'].nil?
            stub['headers'] = update['headers'].merge(update['headers'])
          end
          unless update['status'].nil?
            stub['status'] = update['status']
          end
          unless update['path'].nil?
            stub['path'] = update['path']
          end
          unless update['method'].nil?
            stub['method'] = update['method']
          end
          unless update['body'].nil?
            if stub_body_as_json.nil? and body_as_json.nil?
              stub['body'] = update['body']
            else
              stub['body'] = stub_body_as_json.merge(body_as_json).to_json
            end
          end
          add_stub(stub)
          body ''
        else
          response_with(400, "{\"error\": \"stub with name '#{json['name']}' not found\"}")
        end
      end
    rescue JSON::ParserError
      response_with(400, '{"error":"the body should represent a stub in valid JSON format"}')
    end
  end

  head '/*' do
    route('head', params[:splat].first)
  end

  get '/*' do
    route('get', params[:splat].first)
  end

  post '/*' do
    route('post', params[:splat].first)
  end

  put '/*' do
    route('put', params[:splat].first)
  end

  patch '/*' do
    route('patch', params[:splat].first)
  end

  delete '/*' do
    route('delete', params[:splat].first)
  end

  options '/*' do
    route('options', params[:splat].first)
  end

  private

  def add_stub(stub)
    @@my_routes.delete_if { |r| r['name'] == stub['name'] }
    @@my_routes << stub
    File.write("responses/#{stub["name"]}.json", stub.to_json)
  end

  def route(method, path)
    # puts "method: #{method}, path: #{path}"
    # puts @@my_routes.inspect
    route = @@my_routes.select { |r| r['path'] == "/#{path}" and r['method'] == method }.first
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
