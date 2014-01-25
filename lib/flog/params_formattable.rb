# coding: utf-8
require "action_controller/log_subscriber"
require "awesome_print"
require "flog/payload_value_shuntable"

class ActionController::LogSubscriber
  include Flog::PayloadValueShuntable

  def start_processing_with_flog(event)
    return start_processing_without_flog(event) unless formattable?(event)

    replaced = replace_params(event.payload[:params])

    shunt_payload_value(event.payload, :params, replaced) do
      start_processing_without_flog(event)
    end
  end
  alias_method_chain :start_processing, :flog

  private
  def replace_params(params)
    return params if params.empty? || !params.respond_to?(:ai)

    replaced = params.dup
    class << replaced
      alias :original_except :except

      def except(*keys)
        excepted = original_except(*keys)
        class << excepted
          def inspect
            "\n#{ai(plain: !ActionController::LogSubscriber.colorize_logging)}"
          end
        end
        excepted
      end
    end
    replaced
  end

  def formattable?(event)
    return false unless Flog::Status.params_formattable?

    if Flog.config.force_on_nested_params?
      return true if event.payload[:params].values.any? { |value| value.is_a?(Hash) }
    end

    threshold = Flog.config.params_key_count_threshold.to_i
    threshold += 1 if event.payload[:params].keys.include?("controller")
    threshold += 1 if event.payload[:params].keys.include?("action")
    event.payload[:params].keys.size > threshold
  end
end
