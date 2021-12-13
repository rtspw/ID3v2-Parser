require "bindata"

module Records
  class Header < BinData::Record
    endian :big
    hide :tag_size__
    string :file_id, :read_length => 3
    uint8 :major_version
    uint8 :revision_number
    struct :flags do
      bit1 :unsync
      bit1 :extended_header
      bit1 :experimental
      resume_byte_alignment
    end
    uint32 :tag_size__
    virtual :tag_size, :value => -> { tag_size__ * 4 }
  end
end
