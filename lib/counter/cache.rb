require "counter/cache/version"
require "counter/cache/active_record_updater"
require "counter/cache/options_parser"
require "counter/cache/config"
require "counter/cache/counters/buffer_counter"
require "counter/cache/redis"

module Counter

  module Cache
    def self.configure
      yield configuration
    end

    def self.configuration
      @configuration ||= Counter::Cache::Config.new
    end

    def self.included(base)
      base.instance_eval do
        def counter_cache_on(options)
          on = options.delete(:on).tap { |on| break [on].flatten.map(&:to_sym) unless on.nil? }
          after_create ActiveRecordUpdater.new(options) if on.nil? || on.include?(:create)
          after_destroy ActiveRecordUpdater.new(options) if on.nil? || on.include?(:destroy)
          after_update ActiveRecordUpdater.new(options) if on.present? && on.include?(:update)

          define_method "counter_cache_recount_#{options[:relation]}_#{options[:column]}".to_sym do
            ActiveRecordUpdater.new(options).after_update(self)
          end
        end
      end
    end
  end
end
