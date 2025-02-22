module Sidekiq
  module Tasks
    class Set
      include Enumerable

      def self.match?(object, attributes)
        attributes.any? do |attribute, value|
          [nil, ""].include?(value) || object.public_send(attribute)&.match?(value)
        end
      end

      attr_reader :objects

      def initialize(objects)
        @objects = objects
      end

      def each(&block)
        objects.each(&block)
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

      def size
        objects.size
      end

      def first
        objects[0]
      end

      def last
        objects[-1]
      end

      private

      def reflect(objects)
        self.class.new(objects)
      end
    end
  end
end
