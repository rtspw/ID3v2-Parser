require_relative "id3v2/parser"

$stdout.sync = true

def main(input_filename)
  file_handle = File.open(input_filename, "r")
  Parser.parse(file_handle)
  file_handle.close
end

main("./01\ Another\ Vision.mp3")