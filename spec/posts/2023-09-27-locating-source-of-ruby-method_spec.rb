REGULAR = "locating_source_of_ruby_method_setup/regular_method.rb"
DYNAMIC = "locating_source_of_ruby_method_setup/dynamic_method.rb"

require_relative REGULAR
require_relative DYNAMIC

RSpec.describe "POST: How to locate the source of a Ruby method" do
  context "verify methods work" do
    specify { expect(Foo.new.bar).to eq "BAR!" }
    specify { expect(Dynamic.new.bar).to eq "BAR!" }
    specify { expect(Dynamic.new.foo).to eq "FOO!" }
    specify { expect(Dynamic.new.evald).to eq "EVALD!" }
  end

  describe "source_location" do
    it "works for regular method" do
      expect(Foo.new.method(:bar).source_location).to eq [
        "#{File.dirname(__FILE__)}/#{REGULAR}",
        3
      ]
    end

    it "does not works when trying to access super method directly" do
      expect do
        Class.new(Foo) do
          def bar
            method(:super).source_location
          end
        end.new.bar
      end.to raise_error(NameError)
    end

    it "works when trying to access the super method via super_method method" do
      expect(
        Class.new(Foo) do
          def bar
            self.method(__method__).super_method.source_location
          end
        end.new.bar
      ).to eq [
        "#{File.dirname(__FILE__)}/#{REGULAR}",
        3
      ]
    end

    it "works for dynamic method with a block" do
      expect(Dynamic.new.method(:bar).source_location).to eq [
        "#{File.dirname(__FILE__)}/#{DYNAMIC}",
        6
      ]
    end

    it "works for dynamic method with string source" do
      expect(Dynamic.new.method(:evald).source_location).to eq [
        "(eval)",
        1
      ]
    end

    it "works for dynamic method with a string source and explicit location" do
      expect(Dynamic.new.method(:evald_with_source).source_location).to eq [
        "#{File.dirname(__FILE__)}/#{DYNAMIC}",
        12
      ]
    end
  end

  describe "const_source_location" do
    it "works for a class" do
      expect(Object.const_source_location(:Foo)).to eq [
        "#{File.dirname(__FILE__)}/#{REGULAR}",
        2
      ]
    end
  end
end
