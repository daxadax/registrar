require 'spec_helper'

class ProfileBuilderSpec < Spec
  it 'passes registrar auth hash to callable and stores return value in the env' do
    get '/'
    assert_stores_profile env
  end

  private

  def assert_stores_profile(env)
    profile = env['registrar.profile']

    assert_kind_of ProfileGatewayStub::Profile, profile
    assert_equal '1', profile.internal_uid
    assert_equal 'facebook_123', profile.external_uid
    assert_equal 'Bob', profile.name
  end

  def env
    last_request.env
  end

  def response
    last_response
  end

  def app
    @app ||= build_app
  end

  def build_app
    builder.to_app
  end

  class RegistrarAuthStub
    def initialize(app)
      @app = app
    end

    def call(env)
      auth_hash = {
        'provider' => {
          'name' => 'facebook',
          'uid' => '123'
        },
        'profile' => {
          'name' => 'Bob'
        }
      }
      env['registrar.auth'] = auth_hash
      @app.call(env)
    end

    private

    def stubbed_auth_response
      Marshal.load(auth_response_file)
    end

    def auth_response_file
      File.read(auth_response_path)
    end

    def auth_response_path
      "#{current_path}/fixtures/omniauth_1_0_auth_hash_schema"
    end

    def current_path
      File.expand_path(File.dirname(__FILE__))
    end
  end

  class ProfileGatewayStub
    def call(auth_hash)
      Profile.new(auth_hash)
    end

    class Profile
      attr_reader :internal_uid, :external_uid, :name

      def initialize(auth_hash)
        provider_name = auth_hash['provider']['name']
        uid = auth_hash['provider']['uid']

        @internal_uid = '1'
        @external_uid = "#{provider_name}_#{uid}"
        @name = auth_hash['profile']['name']
      end
    end
  end

  def builder
    Rack::Builder.new do
      use RegistrarAuthStub

      use Registrar::ProfileBuilder, ProfileGatewayStub.new

      app = Proc.new do |env|
        ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
      end

      run app
    end
  end
end
