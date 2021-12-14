require "bindata"

module Records
  class FrameHeader < BinData::Record
    endian :big
    string :frame_id, :length => 4
    uint32 :frame_size

    struct :flags do
      bit1 :tag_alter_preservation
      bit1 :file_alter_preservation
      bit1 :read_only
      resume_byte_alignment
      bit1 :compression
      bit1 :encryption
      bit1 :grouping_identity
      resume_byte_alignment
    end
  end
end
