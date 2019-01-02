require 'sinatra/base'

class Stubinator < Sinatra::Base

  before do
    Dir.glob("responses/*.json") { |path|
      json = JSON.parse(File.read(path))
      self.class.superclass.send(json["method"], json["path"]) do
        unless json["headers"].nil?
          json["headers"].each { |k, v| headers[k] = v }
        end
        unless json["status"].nil?
          status json["status"].to_i
        end
        json["body"] ? json["body"] : ""
      end
    }
  end

  post '/stub' do
    name = params[:name]
    File.write("responses/#{name}.json", request.body.read)
    restart_app
  end

  delete '/stub' do
    name = params[:name]
    File.delete("responses/#{name}.json")
    restart_app
  end

  private

  def restart_app
    app_root = `passenger-status | grep 'App root' | sed 's/^.*: //'`
    system("passenger-config restart-app #{app_root}")
  end

end