require_relative "../lib/id3v2/parser"

describe Parser do
  context "when no header exists" do
    it "should throw BadFormatException" do
      file_name = File.join(File.dirname(__FILE__), "binaries", "no_header.mp3")
      file_handle = File.open file_name
      expect { Parser::parse(file_handle) }.to raise_error(BadFormatException)
      file_handle.close
    end
  end

  context "when unsync flag is set" do
    it "should throw UnsupportedException" do
      file_name = File.join(File.dirname(__FILE__), "binaries", "unsync_flag_on.mp3")
      file_handle = File.open file_name
      expect { Parser::parse(file_handle) }.to raise_error(UnsupportedException)
      file_handle.close
    end
  end

  context "when header is well formatted" do
    it "should correctly parse header" do
      file_name = File.join(File.dirname(__FILE__), "binaries", "short_header.mp3")
      file_handle = File.open file_name
      expect(Parser::parse_header(file_handle)).to eq(
        :file_id => 'ID3',
        :major_version => 3,
        :revision_number => 0,
        :flags => {
          :unsync => 0,
          :extended_header => 0,
          :experimental => 0,
        },
        :tag_size => 15,
      )
      file_handle.close
    end
    it "should parse the length field when it occupies multiple bytes" do
      file_name = File.join(File.dirname(__FILE__), "binaries", "long_tag.mp3")
      file_handle = File.open file_name
      expect(Parser::parse_header(file_handle)).to eq(
        :file_id => 'ID3',
        :major_version => 3,
        :revision_number => 0,
        :flags => {
          :unsync => 0,
          :extended_header => 0,
          :experimental => 0,
        },
        :tag_size => 0b1100101010110,
      )
      file_handle.close
    end
  end

  context "when it includes extended header" do
    it "should throw if header size is invalid" do
      file_name_without_crc = File.join(File.dirname(__FILE__), "binaries", "extended_header_bad_size.mp3")
      file_handle = File.open file_name_without_crc
      expect { Parser::parse(file_handle) }.to raise_error(BadFormatException)
      file_handle.close
    end
    it "should correctly parse extended header when it doesn't include crc" do
      file_name_without_crc = File.join(File.dirname(__FILE__), "binaries", "extended_header_no_crc.mp3")
      file_handle = File.open file_name_without_crc
      expect(Parser::parse_header(file_handle).flags.extended_header).to eq(1)
      expect(Parser::parse_extended_header(file_handle)).to eq(
        :extended_header_size => 6,
        :flags => {
          :crc_present => 0,
        },
        :padding_size => 0,
      )
      file_handle.close
    end
    it "should correctly parse extended header when it includes crc" do
      file_name_with_crc = File.join(File.dirname(__FILE__), "binaries", "extended_header_crc.mp3")
      file_handle = File.open file_name_with_crc
      expect(Parser::parse_header(file_handle).flags.extended_header).to eq(1)
      expect(Parser::parse_extended_header(file_handle)).to eq(
        :extended_header_size => 10,
        :flags => {
          :crc_present => 1,
        },
        :padding_size => 0,
        :crc => 0x12345678,
      )
      file_handle.close
    end
  end
end
