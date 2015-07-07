# TODO see if ActiveModel lets you register a validation
# without polluting global namespace
class AssociatedValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    value.respond_to?(:to_ary) ?
      validate_many(record, attribute, value) :
      validate_one(record, attribute, value)
  end

  private

    def validate_one(record, attribute, value)
      return true if value.nil? || value.marked_for_destruction?

      unless value.valid?
        record.errors.add(attribute, "association error")
      end
    end

    def validate_many(record, attribute, value)
      unless value.reject(&:marked_for_destruction?).all?(&:valid?)
        record.errors.add(attribute, "association error")
      end
    end
end
