require "inflorm/version"
require "active_model"
require "active_support/core_ext/hash/keys"
require "virtus"

require "inflorm/associated_validator"

module Inflorm
  def self.included(base)
    base.class_eval do
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String

      # Need to override Virtus.model to_h, but self.included is run *after* our module
      # is included, so we can't define this method below with the others (unless we prepended)
      # Note we're unfortunately relying on rails monkey patching
      # active_support/core_ext/object/json
      # which will recursively call as_json on all nested objs. Apparently Virtus 2.0 will give us
      # these facilities without relying on it.
      def to_h
        as_json.deep_symbolize_keys
      end
    end
  end

  def persisted?
    id.present?
  end

  def marked_for_destruction?
    respond_to?(marked_for_destruction_param) && send(marked_for_destruction_param).present?
  end

  def save
    valid? && persist!
  end

  protected

    def marked_for_destruction_param
      "_destroy".freeze
    end

    def persist!
      raise "Not Implemented"
    end
end
