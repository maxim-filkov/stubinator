ENV['RACK_ENV'] = 'test'

require_relative '../app.rb'
require 'rack/test'
require 'test/unit'
require 'sinatra'

def app
  @app = Stubinator.new
end

class CreateStubTest < Test::Unit::TestCase
  include Rack::Test::Methods

  %w(get post put delete patch options head).each do |method|
    test "test create stub for '#{method}' method" do
      when_create_stub(
        name: "test_#{method}",
        request_method: method,
        request_path: "/test_#{method}",
        response_status: 200,
        response_body: 'body',
        response_headers: { key: 'value' }
      )
      when_send_request(method, "/test_#{method}")
      then_response_is_equal_to(status: 200, body: method == 'head' ? '' : 'body', headers: { key: 'value' })
    end
  end

  def test_update_stub_request_method
    when_create_stub(
      name: 'test_update_stub_request_method',
      request_method: 'get',
      request_path: '/test_update_stub_request_method',
      response_body: 'body',
      response_headers: {
        'key': 'value'
      })
    when_update_stub(name: 'test_update_stub_request_method', request_method: 'post')
    when_send_request('post', '/test_update_stub_request_method')
    then_response_is_equal_to(status: 200, body: 'body', headers: { key: 'value' })
    when_send_request('get', '/test_update_stub_request_method')
    then_response_is_equal_to(
      status: 404, body: '{"error": "the stub \'GET /test_update_stub_request_method\' hasn\'t been found"}', headers: {}
    )
  end

  def test_update_stub_status
    when_create_stub(
      name: 'test_update_stub_status',
      request_method: 'get',
      request_path: '/test_update_stub_status',
      response_status: 500,
      response_body: 'body',
      response_headers: {
        'key': 'value'
      })
    when_update_stub(name: 'test_update_stub_status', response_status: 300)
    when_send_request('get', '/test_update_stub_status')
    then_response_is_equal_to(status: 300, body: 'body', headers: { key: 'value' })
  end

  def test_update_stub_response_body
    when_create_stub(
      name: 'test_update_stub_response_body',
      request_method: 'post',
      request_path: '/test_update_stub_response_body',
      response_body: 'body',
      response_headers: {
        'key': 'value'
      })
    when_update_stub(name: 'test_update_stub_response_body', response_body: 'body_updated')
    when_send_request('post', '/test_update_stub_response_body')
    then_response_is_equal_to(status: 200, body: 'body_updated', headers: { key: 'value' })
  end

  def test_update_stub_response_headers
    when_create_stub(
      name: 'test_update_stub_response_headers',
      request_method: 'get',
      request_path: '/test_update_stub_response_headers',
      response_body: 'body',
      response_headers: {
        key: 'value'
      })
    when_update_stub(name: 'test_update_stub_response_headers', response_headers: { 'key_updated': 'value_updated' })
    when_send_request('get', '/test_update_stub_response_headers')
    then_response_is_equal_to(status: 200, body: 'body', headers: { 'key_updated': 'value_updated' })
  end

  def test_update_stub_request_body
    when_create_stub(
      name: 'test_update_stub_response_headers',
      request_method: 'post',
      request_path: '/test_update_stub_response_headers',
      response_body: 'body',
      response_headers: {
        'key': 'value'
      },
      request_body: ['[0-9]+']
    )
    when_update_stub(name: 'test_update_stub_response_headers', request_body: ['[a-z]+'])
    when_send_request('post', '/test_update_stub_response_headers', 'abc')
    then_response_is_equal_to(status: 200, body: 'body', headers: { 'key': 'value' })
  end

  def test_update_stub_request_path
    when_create_stub(
      name: 'test_update_stub_request_path',
      request_method: 'get',
      request_path: '/test_update_stub_request_path',
      response_body: 'body',
      response_headers: {
        key: 'value'
      })
    when_update_stub(name: 'test_update_stub_request_path', request_path: '/test_update_stub_request_path123')
    when_send_request('get', '/test_update_stub_request_path')
    then_response_is_equal_to(status: 404, body: '{"error": "the stub \'GET /test_update_stub_request_path\' hasn\'t been found"}', headers: {})
    when_send_request('get', '/test_update_stub_request_path123')
    then_response_is_equal_to(status: 200, body: 'body', headers: { key: 'value' })
  end

  def test_update_nested_json
    when_create_stub(
      name: 'test_update_nested_json',
      request_method: 'get',
      request_path: '/test_update_nested_json',
      response_body: 'body',
      response_headers: {
        'key': { 'nested_key_before': 'nested_value_before' }
      })
    when_update_stub(name: 'test_update_nested_json', response_headers: { 'key': { 'nested_key_after': 'nested_value_after' } })
    when_send_request('get', '/test_update_nested_json')
    then_response_is_equal_to(status: 200, body: 'body', headers: { 'key': { 'nested_key_after': 'nested_value_after' } })
  end

  def test_create_stub_non_json
    post '/stub'
    then_response_is_equal_to(status: 400, body: '{"error":"the body should represent a stub in valid JSON format"}',
                              headers: { 'Content-Type': 'application/json' })
  end

  def test_patch_stub_non_json
    patch '/stub'
    then_response_is_equal_to(status: 400, body: '{"error":"the body should represent a stub in valid JSON format"}',
                              headers: { 'Content-Type': 'application/json' })
  end

  def test_delete_stub_non_json
    delete '/stub'
    then_response_is_equal_to(status: 400, body: '{"error":"the body should represent a stub in valid JSON format"}',
                              headers: { 'Content-Type': 'application/json' })
  end

  def test_stub_get_with_param
    when_create_stub(
      name: 'test_stub_get_with_param',
      request_method: 'get',
      request_path: '/test_stub_get_with_param?param=1',
      response_body: 'body',
      response_headers: {
        'key': 'value'
      })
    when_send_request('get', '/test_stub_get_with_param?param=1')
    then_response_is_equal_to(status: 200, body: 'body', headers: { 'key': 'value' })
  end

  %w(name request_path request_method).each do |param|
    test "test required param '#{param}'" do
      stub = {
        name: "required_param_#{param}",
        request_method: 'get',
        request_path: "/required_param_#{param}"
      }.select { |k, _| k.to_s != param }
      when_create_stub(stub)
      then_response_is_equal_to(
        status: 400,
        body: "{\"error\":\"the '#{param}' field is required\"}",
        headers: {}
      )
    end
  end

  %w(request_body response_headers response_status response_body).each do |param|
    test "test optional param '#{param}'" do
      stub = {
        name: "optional_param_#{param}",
        request_method: 'get',
        request_path: "/optional_param_#{param}",
        request_body: '.*',
        response_headers: { key: 'value' },
        response_status: 200,
        response_body: 'body'
      }.select { |k, _| k.to_s != param }
      when_create_stub(stub)
      assert_equal(200, last_response.status)
    end
  end

  def test_regex_for_body_matches
    when_create_stub(
      name: 'regex_stub1',
      request_body: %w([0-9]+),
      request_method: 'post',
      request_path: '/regex_match',
      response_status: 200,
      response_body: 'body1',
      response_headers: { key1: 'value1' }
    )
    when_create_stub(
      name: 'regex_stub2',
      request_body: %w([6-9]+),
      request_method: 'post',
      request_path: '/regex_match',
      response_status: 200,
      response_body: 'body2',
      response_headers: { key2: 'value2' }
    )
    when_send_request('post', '/regex_match', 'qwe\n111')
    then_response_is_equal_to(status: 200, body: 'body1', headers: { key1: 'value1' })
  end

  def test_regex_for_body_no_match
    when_create_stub(
      name: 'stub_regex_no_match',
      request_body: %w([0-9]+),
      request_method: 'post',
      request_path: '/regex_no_match',
      response_status: 200,
      response_body: 'body',
      response_headers: { key: 'value' }
    )
    when_send_request('post', '/regex_no_match', 'abc')
    then_response_is_equal_to(
      status: 404,
      body: '{"error": "the stub \'POST /regex_no_match\' hasn\'t been found"}',
      headers: {}
    )
  end

  private

  def given_stub(stub)
    create_stub(stub)
  end

  def when_create_stub(stub)
    create_stub(stub)
  end

  def when_update_stub(stub)
    update_stub(stub)
  end

  def when_send_request(method, path, body = '')
    send(method, path, body)
  end

  def then_response_is_equal_to(expected_response)
    assert_equal(expected_response[:status], last_response.status)
    assert_equal(expected_response[:body], last_response.body)
    expected_response[:headers].each do |key, value|
      assert(last_response.headers.key?(key.to_s), "the header with key '#{key}' wasn't found")
      assert_equal(value.to_json, last_response.headers[key.to_s].to_json)
    end
  end

  def create_stub(stub)
    @stubs << stub[:name]
    post '/stub', stub.to_json
  end

  def update_stub(stub)
    patch '/stub', stub.to_json
  end

  def delete_stub(stub)
    delete '/stub', stub['name'].to_json
  end

  setup do
    @stubs = []
  end

  teardown do
    @stubs.each do |stub|
      path = "responses/#{stub}.json"
      File.delete(path) if File.exist?(path)
    end
  end
end
