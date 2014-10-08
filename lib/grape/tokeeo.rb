require "grape"
require "grape/tokeeo/version"

module Grape
  class API
    include Grape::Tokeeo

    class << self
      def ensure_token( options={} )
        Grape::Tokeeo.build_preshared_token_security(options, self) if options[:is].present?
        Grape::Tokeeo.build_model_token_security(options, self) if options[:in].present?
      end

      def ensure_token_with(&block)
        Grape::Tokeeo.secure_with( self, &block)
      end
    end
  end

  module Tokeeo
    DEFAULT_INVALID_MESSAGE = 'Invalid Token'
    DEFAULT_MISSING_MESSAGE = 'Token was not passed'

    class << self

      def message_for_invalid_token( options={} )
        invalid_message_to_use = options[:invalid_message]
        invalid_message_to_use ||= DEFAULT_INVALID_MESSAGE
      end

      def build_preshared_token_security(options, api_instance)
        api_instance.before do
          token = env['X-Api-Token']
          preshared_token = options[:is]

          error!(DEFAULT_MISSING_MESSAGE, 401) unless token.present?
          verification_passed = preshared_token.is_a?(Array) ?  preshared_token.include?(token) : token == preshared_token
          error!( Grape::Tokeeo.message_for_invalid_token(options) , 401) unless verification_passed
        end
      end

      def build_model_token_security(options, api_instance)
        clazz = options[:in]
        field = options[:field]

        raise Error("#{clazz} is not an ActiveRecord::Base subclass") unless clazz < ActiveRecord::Base

        api_instance.before do
          token = env['X-Api-Token']
          found = clazz.find_by("#{field.to_s}" => token )

          error!(DEFAULT_MISSING_MESSAGE, 401) unless token.present?
          error!( Grape::Tokeeo.message_for_invalid_token(options), 401) unless found.present?
        end
      end

      def secure_with(api_instance, &block )
        api_instance.before do
          token = env['X-Api-Token']

          error!( DEFAULT_MISSING_MESSAGE, 401) unless token.present?
          error!( Grape::Tokeeo.message_for_invalid_token(options), 401) unless yield(token)
        end
      end
    end
  end
end
