require "capistrano-haproxy/version"
require "capistrano/configuration/actions/file_transfer_ext"
require "capistrano/configuration/resources/file_resources"
require "erb"
require "uri"

module Capistrano
  module HAProxy
    def self.extended(configuration)
      configuration.load {
        namespace(:haproxy) {
          _cset(:haproxy_path, "/etc/haproxy")

          _cset(:haproxy_global) {{
#           "chroot" => "/usr/share/haproxy",
            "daemon" => "",
            "group" => fetch(:haproxy_group, "haproxy"),
#           "quiet" => "",
            "spread-checks" => 0,
            "user" => fetch(:haproxy_user, "haproxy"),
            "tune.maxaccept" => 100,
          }}
          _cset(:haproxy_defaults) {{
            "balance" => "roundrobin",
            "grace" => 0,
            "log" => "global",
            "maxconn" => fetch(:haproxy_connections, 65535),
            "mode" => "tcp",
            "option" => [
              "clitcpka",
              "contstats",
              "dontlognull",
              "redispatch",
#             "splice-auto",
              "srvtcpka",
#             "transparent",
            ],
            "retries" => 3,
            "timeout" => [
              "client #{fetch(:haproxy_client_tieout, '1h')}",
              "connect #{fetch(:haproxy_connct_timeout, '3s')}",
              "server #{fetch(:haproxy_server_timeout, '1h')}",
            ],
          }}
          _cset(:haproxy_listens, {})
          #
          # Example:
          #
          # set(:haproxy_listens) {{
          #   "stats 127.0.0.1:8888" => {
          #     :mode => "http",
          #     :stats => "uri /server-status",
          #   },
          #   "mysql 127.0.0.1:3306" => {
          #     :mode => "tcp",
          #     :servers => [
          #       "foo foo.example.com:3306 check inter 5000 weight 1",
          #       "bar bar.example.com:3306 check inter 5000 weight 1 backup",
          #     ],
          #   }
          # }}
          #

          desc("Setup HAProxy.")
          task(:setup, :roles => :app, :except => { :no_release => true }) {
            transaction {
              install
              _update
            }
          }
          after 'deploy:setup', 'haproxy:setup'

          desc("Update HAProxy configuration.")
          task(:update, :roles => :app, :except => { :no_release => true }) {
            transaction {
              _update
            }
          }
          # Do not run automatically during normal `deploy' to avoid slow down.
          # If you want to do so, add following line in your ./config/deploy.rb
          #
          # after 'deploy:finalize_update', 'haproxy:update'

          task(:_update, :roles => :app, :except => { :no_release => true }) {
            configure
            reload
          }

          task(:install, :roles => :app, :except => { :no_release => true }) {
            install_dependencies
            install_service
          }

          _cset(:haproxy_platform) {
            capture((<<-EOS).gsub(/\s+/, ' ')).strip
              if test -f /etc/debian_version; then
                if test -f /etc/lsb-release && grep -i -q DISTRIB_ID=Ubuntu /etc/lsb-release; then
                  echo ubuntu;
                else
                  echo debian;
                fi;
              elif test -f /etc/redhat-release; then
                echo redhat;
              else
                echo unknown;
              fi;
            EOS
          }
          _cset(:haproxy_dependencies, %w(haproxy))
          task(:install_dependencies, :roles => :app, :except => { :no_release => true }) {
            unless haproxy_dependencies.empty?
              case haproxy_platform
              when /(debian|ubuntu)/i
                run("#{sudo} apt-get install -q -y #{haproxy_dependencies.join(' ')}")
              when /redhat/i
                run("#{sudo} yum install -q -y #{haproxy_dependencies.join(' ')}")
              else
                # nop
              end
            end
          }

          task(:install_service, :roles => :app, :except => { :no_release => true }) {
            # TODO: setup (sysvinit|daemontools|upstart|runit|systemd) service of HAProxy
          }

          _cset(:haproxy_template_path, File.join(File.dirname(__FILE__), 'capistrano-haproxy', 'templates'))
          _cset(:haproxy_configure_files, %w(/etc/default/haproxy haproxy.cfg))
          task(:configure, :roles => :app, :except => { :no_release => true }) {
            haproxy_configure_files.each do |f|
              safe_put(template(f, :path => haproxy_template_path), ( File.expand_path(f) == f ? f : File.join(haproxy_path, f) ),
                       :place => :if_modified, :sudo => true)
            end
          }

          _cset(:haproxy_service_name, 'haproxy')
          desc("Start HAProxy daemon.")
          task(:start, :roles => :app, :except => { :no_release => true }) {
            run("#{sudo} service #{haproxy_service_name} start")
          }

          desc("Stop HAProxy daemon.")
          task(:stop, :roles => :app, :except => { :no_release => true }) {
            run("#{sudo} service #{haproxy_service_name} stop")
          }

          desc("Restart HAProxy daemon.")
          task(:restart, :roles => :app, :except => { :no_release => true }) {
            run("#{sudo} service #{haproxy_service_name} restart || #{sudo} service #{haproxy_service_name} start")
          }

          desc("Reload HAProxy daemon.")
          task(:reload, :roles => :app, :except => { :no_release => true }) {
            run("#{sudo} service #{haproxy_service_name} reload || #{sudo} service #{haproxy_service_name} start")
          }

          desc("Show HAProxy daemon status.")
          task(:status, :roles => :app, :except => { :no_release => true }) {
            run("#{sudo} service #{haproxy_service_name} status")
          }
        }
      }
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::HAProxy)
end

# vim:set ft=ruby ts=2 sw=2 :
