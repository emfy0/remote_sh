# frozen_string_literal: true
require 'digest/sha1'

module RemoteSh
  module SshHelper
    module_function

    def attach(host, dir)
      system("ssh -t #{host} \"cd #{dir}; exec \$SHELL -l\"")
    end

    def exec(host, dir, args)
      cmd = "cd #{dir}; #{args.join(' ')}"
      system("ssh -t -q #{host} \"#{cmd}\"")
    end

    def current_ports(host, blacklist_ports)
      `ssh #{host} "netstat -tuln | grep LISTEN"`
        .split("\n")
        .map(&:split)
        .map { _1[3].split(':').last }
        .uniq - blacklist_ports
    end

    def normalize_port(port)
      port = port.to_i

      if port == 80 || port == 443
        port += 8000
      elsif port <= 1024
        port += 10000
      end

      port.to_s
    end

    def forward_local_port(host, port)
      normalized_port = normalize_port(port)
      system("ssh -q -f -N -M -S /tmp/remote_local_pf_#{port} -R #{port}:localhost:#{normalized_port} #{host}")
    end

    def close_local_port(host, port)
      system("ssh -q -S /tmp/remote_local_pf_#{port} -O exit #{host}")
    end

    def forward_local_socket(host, socket)
      system("ssh -f -N -M -S /tmp/remote_local_pf_#{Digest::SHA1.hexdigest(socket)} -R #{socket}:#{socket} #{host}")
    end

    def close_local_socket(host, socket)
      system("ssh -q -S /tmp/remote_local_pf_#{Digest::SHA1.hexdigest(socket)} -O exit #{host}")
    end

    def forward_port(host, port)
      normalized_port = normalize_port(port)
      # puts "forwarding #{port} to #{normalized_port}"
      system("ssh -f -N -M -S /tmp/remote_pf_#{port} -L #{normalized_port}:localhost:#{port} #{host}")
    end

    def close_port(host, port)
      # normalized_port = normalize_port(port)
      # puts "closing #{port} forwarded to #{normalized_port}"
      system("ssh -q -S /tmp/remote_pf_#{port} -O exit #{host}")
    end
  end
end
