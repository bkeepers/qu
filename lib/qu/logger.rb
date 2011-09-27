module Qu
  module Logger
    def logger
      Qu.logger
    end

    def log_exception(exception)
      message = "\n#{exception.class} (#{exception.message}):\n  "
      message << clean_backtrace(exception).join("\n  ") << "\n\n"
      logger.fatal(message)
    end

    def clean_backtrace(exception)
      defined?(Rails) && Rails.respond_to?(:backtrace_cleaner) ?
        Rails.backtrace_cleaner.clean(exception.backtrace) :
        exception.backtrace
    end

  end
end