# frozen_string_literal: true

module RemoteSh
  module PortForwarder
    module_function

    def start_or_skip(host_config)
      host_name = host_config["name"]
      host_host = host_config["host"]

      remote_blacklist_ports = host_config["blacklist_ports"]
      local_blacklisted_ports = HostsConfiguration.config["blacklisted_ports"]

      pid_filename = "#{PID_FOLDER}/#{host_name}_portforwarding"

      return if File.exist?(pid_filename)

      # puts "started"

      pid_folder = "#{PID_FOLDER}/#{host_name}"

      local_opened_ports = current_ports(local_blacklisted_ports)
      local_opened_ports.each { |port| SshHelper.forward_local_port(host_host, port) }

      remote_opened_ports = SshHelper.current_ports(host_host, remote_blacklist_ports + local_opened_ports)
      remote_opened_ports.each { |port| SshHelper.forward_port(host_host, port) }

      Process.fork do
        File.open(pid_filename, "w") { |f| f.write("busy") }

        work_loop(
          host_host,
          pid_folder,
          remote_blacklist_ports,
          remote_opened_ports,
          local_blacklisted_ports,
          local_opened_ports
        )
        SshHelper.current_ports(host_host, remote_blacklist_ports + local_opened_ports).each { |port| SshHelper.close_port(host_host, port) }
        current_ports(local_blacklisted_ports + remote_opened_ports).each { |port| SshHelper.close_local_port(host_host, port) }
      rescue
        start_or_skip(host_config)
      ensure
        SshHelper
          .current_ports(host_host, remote_blacklist_ports)
          .each do |port|
            SshHelper.close_port(host_host, port)
          rescue
          end

        current_ports(local_blacklisted_ports)
          .each do |port|
            SshHelper.close_local_port(host_host, port)
          rescue
          end

        File.delete(pid_filename)
      end
    end

    def current_ports(local_blacklisted_ports)
      `lsof -PiTCP -sTCP:LISTEN`
        .split("\n")
        .map(&:split)[1..]
        .map { _1[8].split(":").last }
        .uniq - local_blacklisted_ports
    end

    def work_loop(
      host,
      pid_folder,
      remote_blacklisted_ports,
      remote_opened_ports,
      local_blacklisted_ports,
      local_opened_ports
    )
      until Dir["#{pid_folder}/*"].empty?
        # remote ports
        remote_opened_ports_was = remote_opened_ports
        remote_opened_ports = SshHelper.current_ports(host, remote_blacklisted_ports + local_opened_ports)

        remote_ports_to_close = remote_opened_ports_was - remote_opened_ports
        remote_ports_to_open = remote_opened_ports - remote_opened_ports_was

        remote_ports_to_open.each { |port| SshHelper.forward_port(host, port) }
        remote_ports_to_close.each { |port| SshHelper.close_port(host, port) }

        #local ports

        local_opened_ports_was = local_opened_ports
        local_opened_ports = current_ports(local_blacklisted_ports + remote_opened_ports)

        local_ports_to_close = local_opened_ports_was - local_opened_ports
        local_ports_to_open = local_opened_ports - local_opened_ports_was

        # puts 'local_ports_to_open' + local_ports_to_open.inspect
        local_ports_to_open.each { |port| SshHelper.forward_local_port(host, port) }
        # puts 'local_ports_to_close' + local_ports_to_close.inspect
        local_ports_to_close.each { |port| SshHelper.close_local_port(host, port) }

        sleep(1)
      end
    end
  end
end
