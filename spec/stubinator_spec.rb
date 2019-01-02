ENV['RACK_ENV'] = 'test'

require_relative '../app.rb'
require 'rack/test'
require 'test/unit'
require 'sinatra'

def app
  @app = Stubinator.new
end

class HelloWorldTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def test_possible_to_stub_get
    when_add_endpoint_stub(@stub_name = 'test_get', 'get', '200',
                           { test_header_key: 'test_header_value' }, 'body', '/test_get')
    when_send_request('get', '/test_get')
    then_response_is_equal_to(200, 'body', { test_header_key: 'test_header_value' })
  end

  def test_possible_to_stub_post
    when_add_endpoint_stub(@stub_name = 'tes_post', 'post', '200',
                           { test_header_key: 'test_header_value' }, 'body', '/tes_post')
    when_send_request('post', '/tes_post')
    then_response_is_equal_to(200, 'body', { test_header_key: 'test_header_value' })
  end

  def test_possible_to_stub_delete
    when_add_endpoint_stub(@stub_name = 'test_delete', 'delete', '200',
                           { test_header_key: 'test_header_value' }, 'body', '/test_delete')
    when_send_request('delete', '/test_delete')
    then_response_is_equal_to(200, 'body', { test_header_key: 'test_header_value' })
  end

  def test_possible_to_stub_put
    when_add_endpoint_stub(@stub_name = 'test_put', 'put', '200',
                           { test_header_key: 'test_header_value' }, 'body', '/test_put')
    when_send_request('put', '/test_put')
    then_response_is_equal_to(200, 'body', { test_header_key: 'test_header_value' })
  end

  def test_possible_to_stub_head
    when_add_endpoint_stub(@stub_name = 'test_head', 'head', '200',
                           { test_header_key: 'test_header_value' }, 'body', '/test_head')
    when_send_request('head', '/test_head')
    then_response_is_equal_to(200, '', { test_header_key: 'test_header_value' })
  end

  def test_possible_to_stub_options
    when_add_endpoint_stub(@stub_name = 'test_options', 'options', '200',
                           { test_header_key: 'test_header_value' }, 'body', '/test_options')
    when_send_request('options', '/test_options')
    then_response_is_equal_to(200, 'body', { test_header_key: 'test_header_value' })
  end

  def test_get_stubbing_with_no_body
    when_add_endpoint_stub(@stub_name = 'test_no_body', 'get', '200',
                           { test_header_key: 'test_header_value' }, nil, '/test_no_body')
    when_send_request('get', '/test_no_body')
    then_response_is_equal_to(200, '', { test_header_key: 'test_header_value' })
  end

  def test_stubbing_with_no_status
    when_add_endpoint_stub(@stub_name = 'test_no_status', 'get', nil,
                           { test_header_key: 'test_header_value' }, 'body', '/test_no_status')
    when_send_request('get', '/test_no_status')
    then_response_is_equal_to(200, 'body', { test_header_key: 'test_header_value' })
  end

  def test_stubbing_with_404_status
    when_add_endpoint_stub(@stub_name = 'test_404_status', 'get', '404',
                           { test_header_key: 'test_header_value' }, 'body', '/test_404_status')
    when_send_request('get', '/test_404_status')
    then_response_is_equal_to(404, 'body', { test_header_key: 'test_header_value' })
  end

  teardown do
    delete_endpoint_stub(@stub_name)
  end

  private

  def when_add_endpoint_stub(name, method, status, headers, body, path)
    create_endpoint_stub(name, method, status, headers, body, path)
  end

  def when_send_request(method, path)
    send(method, path)
  end

  def then_response_is_equal_to(status, body, headers)
    assert_equal(status, last_response.status)
    assert_equal(body, last_response.body)
    headers.each do |key, value|
      assert(last_response.headers.has_key?(key.to_s))
      assert_equal(value, last_response.headers[key.to_s])
    end
  end

  def delete_endpoint_stub(name)
    delete "/stub?name=#{name}"
    sleep 3
  end

  def create_endpoint_stub(name, method, status, headers, body, path)
    payload = { method: method, name: name }
    unless status.nil?
      payload["status"] = status
    end
    unless headers.nil?
      payload["headers"] = headers
    end
    unless body.nil?
      payload["body"] = body
    end
    unless path.nil?
      payload["path"] = path
    end
    post "/stub?name=#{name}", payload.to_json
    sleep 3
  end

end
