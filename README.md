# Roda Http Authorization

[![Build Status](https://travis-ci.org/badosu/roda-http-auth.png)](https://travis-ci.org/badosu/roda-http-auth)

Add http authorization methods to Roda.

## Configuration

Configure your Roda application to use this plugin:

```ruby
plugin :http_auth
```

You can pass global options, in this context they'll be shared between all
`r.http_auth` calls.

```ruby
plugin :http_auth, authenticator: proc {|user, pass| [user, pass] == %w[foo bar]},
                   realm: 'Restricted Area', # default
                   schemes: %w[basic] # default
```

## Usage

Call `r.http_auth` inside the routes you want to authenticate the user, it will halt
the request with 401 response code if the authenticator is false.

### Basic Auth

Basic authorization is the default method:

```ruby
# Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
r.http_auth { |user, pass| [user, pass] == ['Aladdin', 'open sesame'] }
```

### Schemes

By default authorization schemes are whitelisted, so if you want to use one
that is not basic auth you must configure it:

```ruby
plugin :http_auth, schemes: %w[bearer]
```

You can also whitelist schemes for a specific route:

```ruby
r.http_auth(schemes: %w[bearer]) { |token| token == '4t0k3n' }
```

### Scheme: Bearer

When the `Bearer` scheme is passed, if whitelisted, the token is passed to
the authenticator:

```ruby
# Authorization: Bearer 4t0k3n
r.http_auth { |token| token == '4t0k3n' }
```

### Schemes with formatted parameters

For schemes that require formatted params authorization header, like `Digest`,
the scheme and the parsed params are passed to the authenticator:

```
# Request
Authorization: Digest username="Mufasa",
                      realm="http-auth@example.org",
                      uri="/dir/index.html",
                      algorithm=MD5,
                      nonce="7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v",
                      nc=00000001,
                      cnonce="f2/wE4q74E6zIJEtWaHKaf5wv/H5QzzpXusqGemxURZJ",
                      qop=auth,
                      response="8ca523f5e9506fed4657c9700eebdbec",
                      opaque="FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS"
```

```ruby
r.http_auth { |s, p| [s, p['username']] == ['digest', 'Mufasa'] }
```

## Warden

To avoid having your 401 responses intercepted by warden, you need to configure
the unauthenticated callback that is called just before the request is halted:

```ruby
plugin :http_auth, unauthorized: proc {|r| r.env['warden'].custom_failure! }
```

## Additional Configuration

The header sent when the user is unauthorized can be configured via
`unauthorized_headers` option, globally or locally:

```ruby
unauthorized_headers: proc do |opts|
  {'Content-Type' => 'text/plain',
   'Content-Length' => '0',
   'WWW-Authenticate' => ('Basic realm="%s"' % opts[:realm])}
end, # default
```

The `unauthorized` option can receive a block to be invoked whenever the user
is unathorized:

```ruby
plugin :http_auth, unauthorized: proc do |r|
  logger.warn("Unathorized attempt to access #{r.path}!!")
end
```

An additional `WWW-Authenticate` header is sent as specified on [rfc7235](https://tools.ietf.org/html/rfc7235#section-4.1) and it's realm can be configured as well.

## Test

```sh
bundle exec ruby test/*.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/badosu/roda-http-auth.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
