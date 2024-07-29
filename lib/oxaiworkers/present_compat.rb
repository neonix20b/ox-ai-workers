module OxAiWorkers
	module PresentCompat
		def present?
			!self.nil? and !self.empty?
		end
	end

	module CamelizeCompat
		def camelize(first_letter = :upper)
		    string = self.dup
			if first_letter == :upper
				string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
			else
				string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
			end
			string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
		end
		
		def underscore
			word = self.dup
			word.gsub!(/::/, '/')
			word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
			word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
			word.tr!("-", "_")
			word.downcase!
			word
		end
	end
end