# frozen_string_literal: true

require 'open3'
require 'webrick'
require 'socket'
require 'filewatcher'

module RemoteSh
  module FileSyncer
    module_function

    def start(host, host_path, ignored_files)
      local_path = WorkspaceConfiguration::WOKRING_DIR

      RsyncHelper.up(local_path, host_path, host, ignored_files)

      mutex = Mutex.new

      Thread.new do
        Filewatcher.new("#{local_path}/**/{.[^\.]*,*}", interval: 1).watch do |_changes|
          if @sync_side == :client || @sync_side.nil?
            mutex.synchronize do
              @sync_side = :clientA
              begin
                RsyncHelper.up(local_path, host_path, host, ignored_files)
                @up_requested = false
              rescue
                @up_requested = true
              end
              do_after_timeout(1) do
                begin
                  RsyncHelper.up(local_path, host_path, host, ignored_files) if @up_requested
                rescue
                end

                mutex.synchronize do
                  @sync_side = nil
                end
              end
            end
          end
        end
      end

      Thread.new do
        start_server(mutex, local_path, host_path, host, ignored_files)
      end
    end

    def do_after_timeout(timeout, &block)
      @thread&.kill

      @thread = Thread.new do
        sleep(timeout)
        block.()
      end
    end

    def start_server(mutex, local_path, host_path, host, ignored_files)
      pid_filename = "#{PID_FOLDER}/#{local_path.gsub("/", "__")}_syncing"
      socket_file = "#{pid_filename}_socket"

      path = socket_file.split("/")[...-1].join("/")

      `ssh #{host} "rm -f #{socket_file}"`
      `ssh #{host} "mkdir -p #{path}"`

      Thread.new do
        ruby_code = <<~RUBY.gsub('"', '\"')
          require "net_http_unix"
          require "filewatcher"

          Thread.new do
            Filewatcher.new("#{host_path}/**/{.[^\.]*,*}", interval: 1).watch do |_changes|
              request = Net::HTTP::Get.new("/request_sync")
              NetX::HTTPUnix.new("unix://" + "#{socket_file}").request(request)
            end
          end

          loop do
            request = Net::HTTP::Get.new("/ping")
            NetX::HTTPUnix.new("unix://" + "#{socket_file}").request(request)
            sleep(3)
          end
        RUBY

        Open3.capture3("ssh -q #{host} 'ruby -e \"#{ruby_code}\"'")
      end

      UNIXServer.open(socket_file) do |ssocket|
        SshHelper.forward_local_socket(host, socket_file)

        server = WEBrick::HTTPServer.new(
          DoNotListen: true,
          Logger: WEBrick::Log.new("/dev/null"),
          AccessLog: [],
        )
        server.listeners << ssocket

        server.mount_proc "/request_sync" do |_req, res|
          if @sync_side == :server || @sync_side.nil?
            mutex.synchronize do
              @sync_side = :server
              begin
                RsyncHelper.down(local_path, host_path, host, ignored_files)
                @down_requested = false
              rescue
                @down_requested = true
              end
              do_after_timeout(1) do
                begin
                  RsyncHelper.down(local_path, host_path, host, ignored_files) if @down_requested
                rescue
                end
                mutex.synchronize { @sync_side = nil }
              end
            end
          end

          res.body = "request_sync"
        end

        server.mount_proc "/ping" do |_req, res|
          res.body = "ping"
        end

        trap("INT") { server.shutdown }

        server.start
      end
    ensure
      SshHelper.close_local_socket(host, socket_file)
      File.unlink(socket_file)
    end
  end
end
