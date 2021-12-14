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

  def self.parse_general_text_information_frame(file_handle:, frame_header:)
    encoding_number = BinData::Uint8be.read(file_handle)
    if encoding_number > 2
      raise BadFormatException.new "Encoding number should be < 2 but got '#{encoding_number}'"
    end
    encoding = @@encodings[encoding_number]
    content_length = frame_header.frame_size - 1
    raw_content = BinData::String.read(file_handle, length: content_length)
    content = convert_to_utf8(raw: raw_content, encoding: encoding)
    return { encoding: encoding, content: content }
  end

  @@frame_parsers = {
    :TALB => method(:parse_general_text_information_frame)
  }

  def self.parse(file_handle)
    frames = {}
    header = parse_header(file_handle)
    extended_header = if header.flags.extended_header == 1
      parse_extended_header(file_handle)
    end
    frame_header = parse_frame_header(file_handle)
    frame_symbol = frame_header.frame_id.to_sym
    frames[frame_symbol] = if @@frame_parsers.has_key? frame_symbol
      frame_body = @@frame_parsers[frame_symbol].call(file_handle: file_handle, frame_header: frame_header)
      [frame_header, frame_body]
    else
      raise BadFormatException.new "Invalid frame id '#{frame_header.frame_id}'"
    end
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

  def self.parse_frame_header(file_handle)
    frame_header = Records::FrameHeader.read(file_handle)
    frame_header
  end
end