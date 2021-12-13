Dir[File.join(__dir__, 'records', '*.rb')].each { |file| require file }

module Records end
  