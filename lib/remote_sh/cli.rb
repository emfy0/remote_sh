# frozen_string_literal: true

require "thor"
require "fileutils"

module RemoteSh
  class Cli < Thor
    desc "attach", "attaches to remote host and starts file sync"
    def attach
      hostname = WorkspaceConfiguration.host_config["name"]

      FileUtils.mkdir_p("#{PID_FOLDER}/#{hostname}")

      local_path = WorkspaceConfiguration::WOKRING_DIR
      pid_filename = "#{PID_FOLDER}/#{hostname}/#{local_path.gsub("/", "__")}"

      unless File.exist?(pid_filename)
        File.open(pid_filename, "w") do |f|
          @owns_sync = true
          f.write("busy")
        end
      end

      host = WorkspaceConfiguration.host_config["host"]
      host_path = WorkspaceConfiguration.config["host_path"]

      if @owns_sync
        FileSyncer.start(host, host_path, WorkspaceConfiguration.config["ignore"] || [])
        PortForwarder.start_or_skip(WorkspaceConfiguration.host_config)
      end

      SshHelper.attach(host, host_path)
    ensure
      File.delete(pid_filename) if @owns_sync
    end
    map 'a' => :attach

    desc "sync_down", "synces down remote changes"
    def sync_down
      RsyncHelper.down(
        WorkspaceConfiguration::WOKRING_DIR,
        WorkspaceConfiguration.config["host_path"],
        WorkspaceConfiguration.host_config["host"],
        WorkspaceConfiguration.config["ignore"] || []
      )
    end

    desc "sync_up", "synces up local changes"
    def sync_up
      RsyncHelper.up(
        WorkspaceConfiguration::WOKRING_DIR,
        WorkspaceConfiguration.config["host_path"],
        WorkspaceConfiguration.host_config["host"],
        WorkspaceConfiguration.config["ignore"] || []
      )
    end

    desc "exec", "executes given command within remote context"
    def exec(*argv)
      host = WorkspaceConfiguration.host_config["host"]
      host_path = WorkspaceConfiguration.config["host_path"]
      SshHelper.exec(host, host_path, argv)
    end
    map 'e' => :exec

    desc "init", "inits"
    def init
      WorkspaceConfiguration.init!
    end
  end
end
