# capistrano-haproxy

a capistrano recipe to setup [HAProxy](http://haproxy.1wt.eu/).

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-haproxy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-haproxy

## Usage

This recipe will setup HAProxy during `deploy:setup` task.

To enable this recipe, add following in your `config/deploy.rb`.

    # in "config/deploy.rb"
    require "capistrano-haproxy"
    set(:haproxy_listens) {{
      "stats 127.0.0.1:8888" => {
        :mode => "http",
        :stats => "uri /server-status",
      }
    }}

Following options are available to configure your HAProxy.

 * `:haproxy_path` - The base path of HAProxy configurations. Use `/etc/haproxy` by default.
 * `:haproxy_global` - The key-value map of `global` options of HAProxy.
 * `:haproxy_defaults` - The key-value map of `defaults` options of HAProxy.
 * `:haproxy_listens` - The definitions of listeners of HAProxy.
 * `:haproxy_dependencies` - The packages of HAProxy.
 * `:haproxy_template_path` - The local path to the configuration templates.
 * `:haproxy_configure_files` - The configuration files of HAProxy.
 * `:haproxy_service_name` - The name of HAProxy service. Use `haproxy` by default.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

- YAMASHITA Yuu (https://github.com/yyuu)
- Geisha Tokyo Entertainment Inc. (http://www.geishatokyo.com/)

## License

MIT
