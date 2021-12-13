require "bindata"
require_relative "records"

class BadFormatException < StandardError
end

class Parser
  def self.parse(file_handle)
    header = parse_header(file_handle)
    puts header
  end

  def self.parse_header(file_handle)
    header = Records::Header.read(file_handle)
    if (header.file_id != 'ID3')
      raise BadFormatException.new "Expected file to start with 'ID3' but was actually '#{header.file_id}'"
    end
    return header
  end
end