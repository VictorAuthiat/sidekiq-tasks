module Sidekiq
  module Tasks
    class Set
      extend Forwardable

      def_delegators :objects, :[], :each, :size, :first, :last, :empty?

      include Enumerable

      def self.match?(object, attributes)
        attributes.any? do |attribute, value|
          next true if [nil, ""].include?(value)

          object_value = object.public_send(attribute).to_s.downcase.gsub(/[^a-z0-9]/, "")
          search_fragments = value.to_s.downcase.gsub(/[^a-z0-9\s]/, "").split

          search_fragments.all? { |fragment| object_value.include?(fragment) }
        end
      end

      attr_reader :objects

      def initialize(objects)
        @objects = objects
      end

      def where(attributes = {})
        reflect(objects.select { |object| self.class.match?(object, attributes) })
      end

      def find_by(name: nil)
        where(name: name).first
      end

      def find_by!(name: nil)
        find_by(name: name) || raise(NotFoundError, "'#{name}' not found")
      end

      private

      def reflect(objects)
        self.class.new(objects)
      end
    end
  end
end
