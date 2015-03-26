module Registrar
  module AuthBuilder
    class OmniAuth
      def initialize(app)
        @app = app
      end

      def call(env)
        try_to_normalize_auth(env)
        @app.call(env)
      end

      private

      def try_to_normalize_auth(env)
        if auth = env['omniauth.auth']
          env['registrar.auth'] = AuthNormalizer.normalized(auth)
        end
      end

      class AuthNormalizer
        def self.normalized(auth)
          new(auth).normalize
        end

        def initialize(auth)
          @auth = auth
        end

        def normalize
          normalized = {}
          normalized['provider'] = normalize_provider
          normalized['profile'] = normalize_profile
          normalized
        end

        private

        attr_reader :auth

        def normalize_provider
          {
            'name' => provider_name,
            'uid' => provider_uid,
            'access_token' => access_token 
          }
        end

        def provider_name
          auth['provider']
        end

        def provider_uid
          auth['uid']
        end

        def access_token
          auth['credentials']['token']
        end

        def normalize_profile
          auth['info'].to_hash
        end
      end
    end
  end
end