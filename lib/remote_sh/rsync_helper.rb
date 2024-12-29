# frozen_string_literal: true

module RemoteSh
  module RsyncHelper
    module_function

    # def create_filters(ignore_paths)
    #   included_files_arg = ""
    #   excluded_files_arg = ""
    #
    #   ignore_paths.each do |path|
    #     expanded_path = "#{WorkspaceConfiguration::WOKRING_DIR}/#{path}"
    #
    #     next unless File.exist?(expanded_path)
    #
    #     File.foreach(expanded_path) do |line|
    #       line = line.strip
    #       next if line.start_with?("#")
    #
    #       if line.start_with?("!")
    #         included_files_arg += "--include='#{line[1..-1]}' "
    #       else
    #         excluded_files_arg += "--exclude='#{line}' "
    #       end
    #     end
    #   end
    #
    #   "#{excluded_files_arg} #{included_files_arg} -f'- .remote_sh'"
    # end

    def up(from, to, host, _ignore_paths)
      # result = `rsync -varz --delete --rsync-path="sudo rsync" #{create_filters(ignore_paths)} #{from}/ #{host}:#{to}/`
      result = `rsync -azl --safe-links --delete --rsync-path="sudo rsync" -f'- .remote_sh' #{from}/ #{host}:#{to}/`
      raise result if $?.exitstatus != 0
      result
    end

    def down(from, to, host, _ignore_paths)
      # result = `rsync -varz --rsync-path="sudo rsync" #{create_filters(ignore_paths)} #{host}:#{to}/ #{from}/`
      result = `rsync -azl --safe-links --rsync-path="sudo rsync" -f'- .remote_sh' #{host}:#{to}/ #{from}/`
      raise result if $?.exitstatus != 0
      result
    end
  end
end
