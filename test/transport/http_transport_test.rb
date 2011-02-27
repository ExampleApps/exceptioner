require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'webmock/test_unit'
require 'json'

class HttpTransportTest < TransportTestCase
  def setup
    super
    config.transports = [:http]
    config.http.api_key = "abcdef"
  end

  def test_deliver_exception_success_by_http
    exception = get_exception
    expect_successful_request(
      :name => exception.class.name,
      :message => exception.message,
      :backtrace => exception.backtrace.join("\n")
    )
    notifier.dispatch(:exception => exception)
  end

  def test_deliver_exception_fail_by_http
    exception = get_exception
    expect_unsuccessful_request(
      :name => exception.class.name,
      :message => exception.message,
      :backtrace => exception.backtrace.join("\n")
    )
    assert_raise Exceptioner::Transport::Http::HttpError do
      notifier.dispatch(:exception => exception)
    end
  end

  def test_require_api_key_option
    # XXX: enable when initialize for transports is working
    #
    # config.http.api_key = nil
    # exception = get_exception
    # Exceptioner::Notifier.stubs(:transports).returns([:http])
    # assert_raise Exceptioner::Transport::Http::ConfigError do
    #   Exceptioner::Notifier.dispatch(exception)
    # end
  end

  protected
  def request_params(message_params)
    {
      :body => { :issue => message_params }.to_json,
      :headers => {
        'API-Key' => config.http.api_key,
        'Content-Type' => 'application/json'
      }
    }
  end

  def expect_successful_request(message_params = {}, uri = "http://exceptioner.com/api/0.1/issues")
    stub_request(:post, uri).with(request_params(message_params))
  end

  def expect_unsuccessful_request(message_params = {}, uri = "http://exceptioner.com/api/0.1/issues")
    stub_request(:post, uri).with(request_params(message_params)).to_return(:status => [500, "Internal Server Error"])
  end
end
