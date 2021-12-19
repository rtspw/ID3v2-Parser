# ID3v2 Decoder

This was mainly to get more familiar with the features and syntax of Ruby but if you somehow found this, please use a more [mature library](https://github.com/krists/id3tag).

Simple parser for ID3V2 tags as per the [specifications](https://id3.org/id3v2.3.0#sec5). Unfortunately the spec is a bit sparse and there's features I've never seen used before, along with some strange things not in the spec I've seen in some real-world files.

Currently only works for V2.3.0 and supports:
- ISO-8859-1 and UTF-16 encoded frames
- Text information frames
- URL frames
- Extended header (Although currently doesn't check CRC match)

but does not currently support:
- Unsynchronization
- Encrypted frames
- ZLIB compressed frames

