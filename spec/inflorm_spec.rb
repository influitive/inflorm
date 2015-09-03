require 'spec_helper'
require 'active_support/core_ext/object/json' # rails gives us this normally

RSpec.describe Inflorm do

  let(:child) {
    Class.new do
      include Inflorm
      attribute :name, String
      attribute :_destroy, Axiom::Types::Boolean, default: false

      validates :name, presence: true

      # Needed due to anonymous class being used
      def self.model_name
        ActiveModel::Name.new(self, nil, "child")
      end
    end
  }

  let(:pet) {
    Class.new do
      include Inflorm
      attribute :name, String
      attribute :species, String, default: "dog"

      validates :name, presence: true

      def self.model_name
        ActiveModel::Name.new(self, nil, "pet")
      end
    end
  }

  let(:parent) {
    child_class = child
    pet_class   = pet

    Class.new do
      include Inflorm
      attribute :name, String
      attribute :email, String
      attribute :children, Array[child_class]
      attribute :pet, pet_class
      attribute :id, String

      validates :email,    presence: true
      validates :children, associated: true
      validates :pet,      associated: true

      def self.model_name
        ActiveModel::Name.new(self, nil, "parent")
      end

      protected

        def persist!
          self.id = 1234
        end
    end
  }

  it "quacks like a model" do
    model = parent.new name: "Bubba", email: ""

    expect(model.name).to eq("Bubba")
    expect(model).to_not be_valid
    expect(model.errors[:email]).to be_present
  end

  context "associations" do
    it "embeds associations" do
      model = parent.new children: [{name: "n1"}, {name: "n2"}]

      expect(model.children[0]).to be_a(child)
      expect(model.children[0].name).to eq("n1")
      expect(model.children[1].name).to eq("n2")
    end

    it "validates has_many associations" do
      model = parent.new email: "whatever", children: [{name: 123}, {name: ""}]

      expect(model).to_not be_valid
      expect(model.children[1].errors[:name]).to include("can't be blank")
    end

    it "validates has_one associations" do
      model = parent.new email: "whatever", pet: {species: "dog", name: ""}

      expect(model).to_not be_valid
      expect(model.pet.errors[:name]).to include("can't be blank")
    end

    it "ignores validations on destroyed associations" do
      model = parent.new email: "whatever", children: [{name: 123}, {name: "", _destroy: true}]

      expect(model).to be_valid
    end
  end

  describe "#persisted?" do
    it "works" do
      p = parent.new
      expect(p).to_not be_persisted

      p = parent.new id: "anything"
      expect(p).to be_persisted

      c = child.new
      expect(c).to_not be_persisted
    end
  end

  describe "#marked_for_destruction?" do
    let(:klass1) {
      Class.new {
        include Inflorm

        def self.model_name
          ActiveModel::Name.new(self, nil, "tmp")
        end
      }
    }

    let(:klass2) {
      Class.new {
        include Inflorm

        attribute :_destrizzle

        def self.model_name
          ActiveModel::Name.new(self, nil, "tmp")
        end

        protected

          def marked_for_destruction_param
            "_destrizzle"
          end
      }
    }

    it "works" do
      p = child.new
      expect(p).to_not be_marked_for_destruction

      p = child.new _destroy: true
      expect(p).to be_marked_for_destruction
    end

    it "is false if the destroy attr isn't specified" do
      obj = klass1.new
      expect(obj).to_not be_marked_for_destruction
    end

    it "allows destroy param to be overridden" do
      obj = klass1.new
      expect(obj).to_not be_marked_for_destruction

      obj = klass2.new _destrizzle: true
      expect(obj).to be_marked_for_destruction
    end
  end

  describe "#save" do
    it "persists only when valid" do
      p = parent.new
      p.save
      expect(p).to_not be_persisted

      p = parent.new email: 'anything'
      p.save
      expect(p).to be_persisted
    end
  end

  describe "#to_h" do
    it "converts everything to a symbolized hash" do
      p = parent.new name: 'blah', children: [{name: 'a'}], pet: {name: "skippy"}

      expect(p.to_h).to match(
        id: nil,
        email: nil,
        name: 'blah',
        children: [
          {name: 'a', _destroy: false}
        ],
        pet: {
          name: "skippy",
          species: "dog"
        }
      )
    end
  end
end
