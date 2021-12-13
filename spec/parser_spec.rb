require_relative "../lib/id3v2/parser"

describe Parser do
  context "when no header exists" do
    it "should throw BadFormatException" do
      file_name = File.join(File.dirname(__FILE__), "binaries", "no_header.mp3")
      file_handle = File.open file_name
      expect { Parser::parse(file_handle) }.to raise_error(BadFormatException)
    end
  end
end
