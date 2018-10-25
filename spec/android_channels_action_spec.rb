describe Fastlane::Actions::AndroidChannelsAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The android_channels plugin is working!")

      Fastlane::Actions::AndroidChannelsAction.run(nil)
    end
  end
end
