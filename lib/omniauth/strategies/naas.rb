require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Naas < OmniAuth::Strategies::OAuth2
      option :name, "naas"
      option :scope, 'naas.full'
      option :scopes, 'naas.full'

      option :client_options, {
        :site          => 'https://naas-api-local.deviceindependent.com',
        :authorize_url => 'https://naas-api-local.deviceindependent.com/oauth/authorize',
        :token_url     => 'https://naas-api-local.deviceindependent.com/oauth/token'
      }

      option :authorize_options, [:scope]

      def authorize_params
        super.tap do |params|
          %w[scope scopes redirect_uri].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

      def request_phase
        url = client.auth_code.authorize_url({ redirect_uri: callback_url }.merge(authorize_params))
        redirect(url)
      end

      uid do
        raw_info['id'].to_s
      end

      info do
        {
          'id'              => user_profile_info['id'],
          'type'            => user_profile_info['type'],
          'first_name'      => user_profile_info['first_name'],
          'last_name'       => user_profile_info['last_name'],
          'email'           => user_profile_info['email'],
          'created_at'      => user_profile_info['created_at'],
          'updated_at'      => user_profile_info['updated_at'],
          'links'           => user_profile_info['links']
        }
      end

      def raw_info
        @raw_info ||= access_token.get(user_info_url).parsed
      end

      def user_profile_info
        @user_profile_info ||= raw_info.fetch('user_profile', {})
      end

      def user_info_url
        "/auth/me"
      end

      def callback_url
        url = full_host + script_name + callback_path
        url
      end

      protected
      def build_access_token
        verifier = request.params['code']
        url = client.auth_code.get_token(verifier, token_params.to_hash(symbolize_keys: true), deep_symbolize(options.auth_token_params))
        url
      end
    end
  end
end

