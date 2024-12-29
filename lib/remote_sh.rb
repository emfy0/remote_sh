# frozen_string_literal: true

require "zeitwerk"
require "singleton"

loader = Zeitwerk::Loader.for_gem
loader.setup

module RemoteSh
  PID_FOLDER = "/tmp/remote_sh"
end
