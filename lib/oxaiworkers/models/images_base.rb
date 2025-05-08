module OxAiWorkers
  module Models
    class ImagesBase
      attr_accessor :client, :options, :qualities, :sizes, :result

      def initialize(options:)
        @options = options
      end
    end
  end
end
