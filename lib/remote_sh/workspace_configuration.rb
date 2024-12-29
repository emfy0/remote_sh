# frozen_string_literal: true

require "yaml"

module RemoteSh
  class WorkspaceConfiguration
    include Singleton

    WOKRING_DIR = Dir.pwd
    CONFIGURATION_FILE = "#{WOKRING_DIR}/.remote_sh/connection.yaml"

    # host: name_from_config
    # host_path: path_on_server
    # ignore: ...

    def self.config
      instance.config
    end

    def self.host_config
      instance.host_config
    end

    def self.init!
      current_path = Dir.getwd

      default_server = HostsConfiguration.config['default_server']
      default_remote_root_path = HostsConfiguration.config['default_remote_root_path']
      default_local_root_path = HostsConfiguration.config['default_local_root_path']

      Dir.mkdir("#{current_path}/.remote_sh")

      current_relative_path = current_path.delete_prefix(default_local_root_path)

      remote_path = "#{default_remote_root_path}#{current_relative_path}"
      host = HostsConfiguration.config['servers'].find { |s| s['name'] == default_server }['host']

      `ssh #{host} "mkdir -p #{remote_path}"`

      File.open("#{Dir.getwd}/.remote_sh/connection.yaml", 'w') do |file|
        file.write(<<~YAML)
          host: main
          host_path: #{remote_path}
          ignore:
            - .gitignore
        YAML
      end
    end

    def parse
      @config = YAML.load_file(CONFIGURATION_FILE)
    end

    def config
      @config || parse
    end

    def host_config
      @host_config ||=
        HostsConfiguration.config["servers"].find { _1["name"] == config["host"] }
    end
  end
end
