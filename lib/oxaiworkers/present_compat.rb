# frozen_string_literal: true

module OxAiWorkers
  module PresentCompat
    def present?
      !nil? and !empty?
    end
  end

  module CamelizeCompat
    def camelize(first_letter = :upper)
      string = dup
      string = if first_letter == :upper
                 string.sub(/^[a-z\d]*/, &:capitalize)
               else
                 string.sub(/^(?:(?=\b|[A-Z_])|\w)/, &:downcase)
               end
      string.gsub(%r{(?:_|(/))([a-z\d]*)}) do
        "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).capitalize}"
      end.gsub('/', '::')
    end

    def underscore
      word = dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end
  end
end
