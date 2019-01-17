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
    when_create_stub('test_get', 'get', '200', { test_header_key: 'test_header_value' }, 'body', '/test_get')
    when_send_request('get', '/test_get')
    then_response_is_equal_to(200, 'body', test_header_key: 'test_header_value')
  end

  def test_possible_to_stub_post
    when_create_stub('tes_post', 'post', '200', { test_header_key: 'test_header_value' }, 'body', '/tes_post')
    when_send_request('post', '/tes_post')
    then_response_is_equal_to(200, 'body', test_header_key: 'test_header_value')
  end

  def test_possible_to_stub_delete
    when_create_stub('test_delete', 'delete', '200', { test_header_key: 'test_header_value' }, 'body', '/test_delete')
    when_send_request('delete', '/test_delete')
    then_response_is_equal_to(200, 'body', test_header_key: 'test_header_value')
  end

  def test_possible_to_stub_put
    when_create_stub('test_put', 'put', '200', { test_header_key: 'test_header_value' }, 'body', '/test_put')
    when_send_request('put', '/test_put')
    then_response_is_equal_to(200, 'body', test_header_key: 'test_header_value')
  end

  def test_possible_to_stub_head
    when_create_stub('test_head', 'head', '200', { test_header_key: 'test_header_value' }, 'body', '/test_head')
    when_send_request('head', '/test_head')
    then_response_is_equal_to(200, '', test_header_key: 'test_header_value')
  end

  def test_possible_to_stub_options
    when_create_stub('test_options', 'options', '200', { test_header_key: 'test_header_value' }, 'body', '/test_options')
    when_send_request('options', '/test_options')
    then_response_is_equal_to(200, 'body', test_header_key: 'test_header_value')
  end

  def test_get_stubbing_with_no_body
    when_create_stub('test_no_body', 'get', '200', { test_header_key: 'test_header_value' }, nil, '/test_no_body')
    when_send_request('get', '/test_no_body')
    then_response_is_equal_to(200, '', test_header_key: 'test_header_value')
  end

  def test_stubbing_with_no_status
    when_create_stub('test_no_status', 'get', nil, { test_header_key: 'test_header_value' }, 'body', '/test_no_status')
    when_send_request('get', '/test_no_status')
    then_response_is_equal_to(200, 'body', test_header_key: 'test_header_value')
  end

  def test_stubbing_with_no_path
    when_create_stub('test_no_path', 'get', '200', { test_header_key: 'test_header_value' }, 'body', nil)
    then_response_is_equal_to(400, '{"error":"the \'path\' field is required"}',
                              'Content-Type': 'application/json')
  end

  def test_stubbing_with_no_method
    when_create_stub('test_no_method', nil, '200', { test_header_key: 'test_header_value' }, 'body', '/test_no_method')
    then_response_is_equal_to(400, '{"error":"the \'method\' field is required"}',
                              'Content-Type': 'application/json')
  end

  def test_stubbing_with_404_status
    when_create_stub('test_404_status', 'get', '404', { test_header_key: 'test_header_value' }, 'body', '/test_404_status')
    when_send_request('get', '/test_404_status')
    then_response_is_equal_to(404, 'body', test_header_key: 'test_header_value')
  end

  def test_update_stub_method
    given_endpoint_stub(name: 'test_method_update',
                        method: 'get',
                        status: 200,
                        headers: { 'Content-Type': 'application/json' },
                        body: '{"key":"value"}',
                        path: '/test_method_update')
    when_update_stub(name: 'test_method_update', method: 'post')
    when_send_request('post', '/test_method_update')
    then_response_is_equal_to(200, '{"key":"value"}', 'Content-Type': 'application/json')
  end

  def test_update_stub_status
    given_endpoint_stub(name: 'test_status_update',
                        method: 'get',
                        status: 200,
                        headers: { 'Content-Type': 'application/json' },
                        body: '{"key":"value"}',
                        path: '/test_status_update')
    when_update_stub(name: 'test_status_update', status: 502)
    when_update_stub(name: 'test_status_update', status: 502)
    when_send_request('get', '/test_status_update')
    then_response_is_equal_to(502, '{"key":"value"}', 'Content-Type': 'application/json')
  end

  def test_update_stub_path
    given_endpoint_stub(name: 'test_path_update',
                        method: 'get',
                        status: 200,
                        headers: { 'Content-Type': 'application/json' },
                        body: '{"key":"value"}',
                        path: '/test_path_update_before')
    when_update_stub(name: 'test_path_update', path: '/test_status_update_after')
    when_send_request('get', '/test_status_update_after')
    then_response_is_equal_to(200, '{"key":"value"}', 'Content-Type': 'application/json')
  end

  def test_update_stub_headers
    given_endpoint_stub(name: 'test_headers_update',
                        method: 'get',
                        status: 200,
                        headers: { 'Content-Type': 'application/json' },
                        body: '{"key":"value"}',
                        path: '/test_headers_update')
    when_update_stub(name: 'test_headers_update', headers: { 'new_header': 'foo' })
    when_send_request('get', '/test_headers_update')
    then_response_is_equal_to(200, '{"key":"value"}', 'new_header': 'foo')
  end

  def test_update_stub_body
    given_endpoint_stub(name: 'test_body_update',
                        method: 'get',
                        status: 200,
                        headers: { 'Content-Type': 'application/json' },
                        body: '{"key1":"value1_before","key2":"value2"}',
                        path: '/test_body_update')
    when_update_stub(name: 'test_body_update', body: '{"key1":"value1_after"}')
    when_send_request('get', '/test_body_update')
    then_response_is_equal_to(200, '{"key1":"value1_after","key2":"value2"}',
                              'Content-Type': 'application/json')
  end

  def test_update_nested_json
    given_endpoint_stub(name: 'test_nested_json_update',
                        method: 'get',
                        status: 200,
                        headers: { 'Content-Type': 'application/json' },
                        body: '{"key":{"nested_key_before":"nested_value_before"}}',
                        path: '/test_nested_json_update')
    when_update_stub(name: 'test_nested_json_update', body: '{"key":{"nested_key_after":"nested_value_after"}}')
    when_send_request('get', '/test_nested_json_update')
    then_response_is_equal_to(200, '{"key":{"nested_key_after":"nested_value_after"}}',
                              'Content-Type': 'application/json')
  end

  def test_create_stub_no_name
    post '/stub', '{"key":"value"}'
    then_response_is_equal_to(400, '{"error":"the \'name\' field is required"}',
                              'Content-Type': 'application/json')
  end

  def test_update_stub_no_name
    patch '/stub', '{"key":"value"}'
    then_response_is_equal_to(400, '{"error":"the \'name\' field is required"}',
                              'Content-Type': 'application/json')
  end

  def test_delete_stub_no_name
    delete '/stub', '{}'
    then_response_is_equal_to(400, '{"error":"the \'name\' field is required"}',
                              'Content-Type': 'application/json')
  end

  def test_create_stub_non_json
    post '/stub'
    then_response_is_equal_to(400, '{"error":"the body should represent a stub in valid JSON format"}',
                              'Content-Type': 'application/json')
  end

  def test_patch_stub_non_json
    patch '/stub'
    then_response_is_equal_to(400, '{"error":"the body should represent a stub in valid JSON format"}',
                              'Content-Type': 'application/json')
  end

  def test_delete_stub_non_json
    delete '/stub'
    then_response_is_equal_to(400, '{"error":"the body should represent a stub in valid JSON format"}',
                              'Content-Type': 'application/json')
  end

  def test_stub_get_with_param
    when_create_stub('test_get', 'get', '200', { test_header_key: 'test_header_value' }, 'body', '/test_get?param=1')
    when_send_request('get', '/test_get?param=1')
    then_response_is_equal_to(200, 'body', test_header_key: 'test_header_value')
  end

  private

  def given_endpoint_stub(name:, method:, status: nil, headers: {}, body: '', path: nil)
    create_stub(name, method, status, headers, body, path)
  end

  def when_create_stub(name, method, status, headers, body, path)
    create_stub(name, method, status, headers, body, path)
  end

  def when_update_stub(name:, path: nil, method: nil, status: nil, headers: nil, body: nil)
    update_stub(name, method, status, headers, body, path)
  end

  def when_send_request(method, path)
    send(method, path)
  end

  def then_response_is_equal_to(status, body, headers)
    assert_equal(status, last_response.status)
    assert_equal(body, last_response.body)
    headers.each do |key, value|
      assert(last_response.headers.key?(key.to_s), "the header with key '#{key}' wasn't found")
      assert_equal(value, last_response.headers[key.to_s])
    end
  end

  teardown do
    delete_stub(@stub_name)
  end

  def create_stub(name, method, status, headers, body, path)
    @stub_name = name
    payload = { method: method, name: name }
    payload['status'] = status unless status.nil?
    payload['headers'] = headers unless headers.nil?
    payload['body'] = body unless body.nil?
    payload['path'] = path unless path.nil?
    post '/stub', payload.to_json
  end

  def update_stub(name, method, status, headers, body, path)
    payload = { name: name }
    payload['method'] = method unless method.nil?
    payload['status'] = status unless status.nil?
    payload['headers'] = headers unless headers.nil?
    payload['body'] = body unless body.nil?
    payload['path'] = path unless path.nil?
    patch '/stub', payload.to_json
  end

  def delete_stub(name)
    File.delete("responses/#{name}.json") if File.exist?("responses/#{name}.json")
  end
end
