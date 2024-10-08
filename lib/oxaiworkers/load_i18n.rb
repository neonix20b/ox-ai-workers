# frozen_string_literal: true

unless defined?(Rails)
  require 'i18n'
  I18n.load_path += Dir["#{File.expand_path('../../config/locales', __dir__)}/*.yml"]
end

module OxAiWorkers
  module LoadI18n
    attr_accessor :locale

    def with_locale(&action)
      # locale = respond_to?(:locale) ? self.locale : OxAiWorkers.configuration.locale
      I18n.with_locale(@locale, &action)
    end

    def store_locale
      @locale = I18n.locale
    end
  end
end
