require "roda"
require "roda/plugins/http_auth/version"

module Roda::RodaPlugins
  module HttpAuth
    DEFAULTS = {
      realm: "Restricted Area",
      unauthorized_headers: proc do |opts|
        {'Content-Type' => 'text/plain',
         'Content-Length' => '0',
         'WWW-Authenticate' => ('Basic realm="%s"' % opts[:realm])}
      end,
      bad_request_headers: proc do |opts|
        {'Content-Type' => 'text/plain', 'Content-Length' => '0'}
      end,
      schemes: %w[basic]
    }

    def self.configure(app, opts={})
      plugin_opts = (app.opts[:http_auth] ||= DEFAULTS)
      app.opts[:http_auth] = plugin_opts.merge(opts)
      app.opts[:http_auth].freeze
    end

    module RequestMethods
      def http_auth(opts={}, &authenticator)
        auth_opts = roda_class.opts[:http_auth].merge(opts)
        authenticator ||= auth_opts[:authenticator]

        raise "Must provide an authenticator block" if authenticator.nil?

        begin
          auth = Rack::Auth::Basic::Request.new(env)

          unless auth.provided? && auth_opts[:schemes].include?(auth.scheme)
            auth_opts[:unauthorized].call(self) if auth_opts[:unauthorized]
            halt [401, auth_opts[:unauthorized_headers].call(auth_opts), []]
          end

          credentials = if auth.basic?
                          auth.credentials
                        elsif auth.scheme == 'bearer'
                          [env['HTTP_AUTHORIZATION'].split(' ', 2).last]
                        else
                          http_auth = env['HTTP_AUTHORIZATION'].split(' ', 2)
                                                               .last

                          creds = !http_auth.include?('=') ? http_auth :
                                    Rack::Auth::Digest::Params.parse(http_auth)

                          [auth.scheme, creds]
                        end

          if authenticator.call(*credentials)
            env['REMOTE_USER'] = auth.username
          else
            opts[:unauthorized].call(self) if auth_opts[:unauthorized]
            halt [401, auth_opts[:unauthorized_headers].call(auth_opts), []]
          end
        rescue StandardError
          halt [400, auth_opts[:bad_request_headers].call(auth_opts), []]
        end
      end
    end
  end

  register_plugin(:http_auth, HttpAuth)
end
