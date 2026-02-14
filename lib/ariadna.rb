require_relative "ariadna/version"

module Ariadna
  class Error < StandardError; end

  def self.gem_root
    File.expand_path("..", __dir__)
  end

  def self.data_dir
    File.join(gem_root, "data")
  end
end
