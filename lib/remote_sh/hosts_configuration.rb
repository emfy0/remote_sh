# frozen_string_literal: true

require "yaml"

module RemoteSh
  class HostsConfiguration
    include Singleton

    CONFIGURATION_PATH = "#{Dir.home}/.config/remote_sh"
    CONFIGURATION_FILE = "#{CONFIGURATION_PATH}/servers.yaml"

    # servers:
    # - name: main
    #   host: root@127.0.0.1
    #   blacklist_ports: ['22', '25', '631']

    def self.config
      instance.config
    end

    def parse
      FileUtils.mkdir_p(CONFIGURATION_PATH)
      @config = YAML.load_file(CONFIGURATION_FILE)
    end

    def config
      @config || parse
    end
  end
end
