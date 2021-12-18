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
    array :tag_size__, :type => :bit1, :initial_length => 32
    virtual :tag_size, :value => -> {
      bit_arr = tag_size__.to_a
      bit_arr[0] = 'x'
      bit_arr[8] = 'x'
      bit_arr[16] = 'x'
      bit_arr[24] = 'x'
      return Integer(bit_arr.join('').gsub('x', ''), 2)
    }
  end
end
