require "spec_helper"
require "tempfile"
require "thor"

RSpec.describe Dctl::Main do
  describe "#define_custom_commands" do
    it "defines a command on the passed class" do
      config = <<~CONFIG
        org: jutonz
        project: dctl_rb
        custom_commands:
          single: pwd
          multiple: ["pwd", "whoami"]
      CONFIG

      with_config(config) do |config_path|
        dctl = Dctl::Main.new(config: config_path)
        klass = Class.new(Thor)

        dctl.define_custom_commands(klass)

        expect(klass.commands.key?("single")).to be true
        expect(klass.commands.key?("multiple")).to be true
      end
    end

    it "is okay if there are no custom commands" do
      config = <<~CONFIG
        org: jutonz
        project: dctl_rb
      CONFIG

      with_config(config) do |config_path|
        dctl = Dctl::Main.new(config: config_path)
        klass = Class.new(Thor)

        expect {
          dctl.define_custom_commands(klass)
        }.to_not raise_error
      end
    end
  end

  describe "#image_tag" do
    it "returns a tag" do
      config = <<~CONFIG
        org: jutonz
        project: dctl_rb
      CONFIG

      with_config(config) do |config_path|
        dctl = Dctl::Main.new(config: config_path)
        service = "app"

        expect(dctl).to receive(:current_version_for_image).with(service)
          .and_return(10)

        expect(dctl.image_tag(service)).to eq "jutonz/dctl_rb-dev-app:10"
      end
    end

    it "allows specifying negative version numbers" do
      config = <<~CONFIG
        org: jutonz
        project: dctl_rb
      CONFIG

      with_config(config) do |config_path|
        dctl = Dctl::Main.new(config: config_path)
        service = "app"

        expect(dctl).to receive(:current_version_for_image).with(service)
          .and_return(10)

        expect(dctl.image_tag(service, version: -1)).to eq(
          "jutonz/dctl_rb-dev-app:9"
        )
      end
    end
  end
end

def with_config(config_str, &block)
  Tempfile.open [".dctl", ".yml"] do |tf|
    tf.write config_str
    tf.flush
    yield tf.path
  end
end
