require "bindata"

module Records
  class ExtendedHeader < BinData::Record
    endian :big
    uint32 :extended_header_size
    struct :flags do
      bit1 :crc_present
      resume_byte_alignment
    end
    skip :length => 1
    uint32 :padding_size
    uint32 :crc, :onlyif => :crc_present?

    def crc_present?
      flags.crc_present == 1
    end
  end
end
