require "bindata"
require_relative "records"

class BadFormatException < StandardError
end

class UnsupportedException < StandardError
end

class Parser

  @@encodings = {
    0 => 'ASCII',
    1 => 'UTF-16',
    2 => 'UTF-16BE',
    3 => 'UTF-8',
  }

  def self.convert_to_utf8(raw:, encoding:)
    case encoding
    when 'ASCII'
      raw.strip
    when 'UTF-16'
      raw.force_encoding('UTF-16').encode('UTF-8').strip
    else
      raw
    end
  end

  def self.parse(file_handle)
    header = parse_header(file_handle)
    extended_header = if header.flags.extended_header == 1
      parse_extended_header(file_handle)
    end
    puts header
    puts extended_header
  end

  def self.parse_header(file_handle)
    header = Records::Header.read(file_handle)
    if header.file_id != 'ID3'
      raise BadFormatException.new "Expected file to start with 'ID3' but was actually '#{header.file_id}'"
    end
    if header.flags.unsync == 1
      raise UnsupportedException.new "Unsynchronization is not supported"
    end
    header
  end

  def self.parse_extended_header(file_handle)
    extended_header = Records::ExtendedHeader.read(file_handle)
    if extended_header.extended_header_size != 6 && extended_header.extended_header_size != 10
      raise BadFormatException.new "Extended header size should by 6 or 10 but was actually '#{extended_header.extended_header_size}"
    end
    extended_header
  end
end