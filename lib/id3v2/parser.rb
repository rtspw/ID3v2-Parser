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

  def self.parse_custom_text_information_frame(file_handle:, frame_header:)
    encoding_number = BinData::Uint8be.read(file_handle)
    if encoding_number > 2
      raise BadFormatException.new "Encoding number should be < 2 but got '#{encoding_number}'"
    end
    encoding = @@encodings[encoding_number]
    content_length = frame_header.frame_size - 1
    raw_content = BinData::String.read(file_handle, length: content_length)
    content = convert_to_utf8(raw: raw_content, encoding: encoding)
    desc, value = case encoding
    when "UTF-16"
      content.split("\u0000")
    when "ASCII"
      content.split(" ")
    end
    return { encoding: encoding, content: { description: desc, value: value } }
  end

  def self.parse_slash_separated_text_information_frame(file_handle:, frame_header:)
    result = parse_general_text_information_frame(file_handle: file_handle, frame_header: frame_header)
    result[:content] = result[:content].split '/'
    return result
  end

  def self.parse_text_information_frame_as_number(file_handle:, frame_header:)
    result = parse_general_text_information_frame(file_handle: file_handle, frame_header: frame_header)
    result[:content] = Integer(result[:content])
    return result
  end

  def self.parse_text_information_frame_as_year(file_handle:, frame_header:)
    result = parse_general_text_information_frame(file_handle: file_handle, frame_header: frame_header)
    if result[:content].length != 4
      raise BadFormatException.new "Could not parse year '#{result.content}' in frame '#{result.frame_id.to_s}'"
    end
    result[:content] = Integer(result[:content])
    return result
  end

  def self.parse_url_frame(file_handle:, frame_header:)
    content_length = frame_header.frame_size
    content = BinData::String.read(file_handle, length: content_length)
    return content
  end

  @@frame_parsers = {
    :TALB => method(:parse_general_text_information_frame),
    :TBPM => method(:parse_text_information_frame_as_number),
    :TCOM => method(:parse_slash_separated_text_information_frame),
    :TCON => method(:parse_general_text_information_frame), # incomplete
    :TCOP => method(:parse_general_text_information_frame),
    :TDAT => method(:parse_general_text_information_frame), # incomplete
    :TDLY => method(:parse_text_information_frame_as_number), # incomplete
    :TENC => method(:parse_general_text_information_frame),
    :TEXT => method(:parse_slash_separated_text_information_frame),
    :TFLT => method(:parse_general_text_information_frame), # incomplete
    :TIME => method(:parse_general_text_information_frame), # incomplete
    :TIT1 => method(:parse_general_text_information_frame),
    :TIT2 => method(:parse_general_text_information_frame),
    :TIT3 => method(:parse_general_text_information_frame),
    :TKEY => method(:parse_general_text_information_frame), # incomplete
    :TLAN => method(:parse_general_text_information_frame),
    :TLEN => method(:parse_text_information_frame_as_number),
    :TMED => method(:parse_general_text_information_frame), # incomplete
    :TOAL => method(:parse_general_text_information_frame),
    :TOFN => method(:parse_general_text_information_frame),
    :TOLY => method(:parse_slash_separated_text_information_frame),
    :TOPE => method(:parse_slash_separated_text_information_frame),
    :TORY => method(:parse_text_information_frame_as_year), # incomplete
    :TOWN => method(:parse_general_text_information_frame),
    :TPE1 => method(:parse_slash_separated_text_information_frame),
    :TPE2 => method(:parse_general_text_information_frame),
    :TPE3 => method(:parse_general_text_information_frame),
    :TPE4 => method(:parse_general_text_information_frame),
    :TPOS => method(:parse_general_text_information_frame), # incomplete
    :TPUB => method(:parse_general_text_information_frame),
    :TRCK => method(:parse_general_text_information_frame), # incomplete
    :TRDA => method(:parse_general_text_information_frame),
    :TRSN => method(:parse_general_text_information_frame),
    :TRSO => method(:parse_general_text_information_frame),
    :TSIZ => method(:parse_text_information_frame_as_number), # incomplete
    :TSRC => method(:parse_general_text_information_frame), # incomplete
    :TSSE => method(:parse_general_text_information_frame),
    :TYER => method(:parse_text_information_frame_as_year), # incomplete
    :TDRC => method(:parse_text_information_frame_as_year), # NOT IN SPEC?! Appears to be the same as TYER
    :TXXX => method(:parse_custom_text_information_frame),
    :WCOM => method(:parse_url_frame),
    :WCOP => method(:parse_url_frame),
    :WOAF => method(:parse_url_frame),
    :WOAR => method(:parse_url_frame),
    :WOAS => method(:parse_url_frame),
    :WORS => method(:parse_url_frame),
    :WPAY => method(:parse_url_frame),
    :WPUB => method(:parse_url_frame),
  }

  def self.parse(file_handle)
    frames = {}
    header = parse_header(file_handle)
    bits_remaining = header.tag_size
    extended_header = if header.flags.extended_header == 1
      extended_header = parse_extended_header(file_handle)
      bits_remaining -= extended_header.extended_header_size
      extended_header
    end
    while bits_remaining > 0 do
      frame_header = parse_frame_header(file_handle)
      frame_symbol = frame_header.frame_id.to_sym
      frame_info =
        if @@frame_parsers.has_key? frame_symbol
          frame_body = @@frame_parsers[frame_symbol].call(file_handle: file_handle, frame_header: frame_header)
          { :header => frame_header, :body => frame_body }
        else
          raise BadFormatException.new "Invalid frame id '#{frame_header.frame_id}'"
        end
      case frame_symbol
      when :TXXX
        if frames[:TXXX].nil?
          frames[:TXXX] = []
        end
        frames[:TXXX] << frame_info
      when :WXXX
        if frames[:WXXX].nil?
          frames[:WXXX] = []
        end
        frames[:WXXX] << frame_info
      else
        frames[frame_symbol] = frame_info
      end
      bits_remaining -= (frame_header.frame_size + 10)
    end
    return { header: header, frames: frames }
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