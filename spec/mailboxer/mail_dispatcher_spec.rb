require 'spec_helper'

describe Mailboxer::MailDispatcher do

  subject(:instance) { described_class.new(mailable, recipients) }

  let(:mailable)   { Mailboxer::Motification.new }
  let(:recipient1) { double 'recipient1', mailboxer_email: ''  }
  let(:recipient2) { double 'recipient2', mailboxer_email: 'foo@bar.com'  }
  let(:recipients) { [ recipient1, recipient2 ] }

  describe "call" do
    context "no emails" do
      before { Mailboxer.uses_emails = false }
      after  { Mailboxer.uses_emails = true }
      its(:call) { should be_false }
    end

    context "mailer wants array" do
      before { Mailboxer.mailer_wants_array = true  }
      after  { Mailboxer.mailer_wants_array = false }
      it 'sends collection' do
        subject.should_receive(:send_email).with(recipients)
        subject.call
      end
    end

    context "mailer doesnt want array" do
      it 'sends collection' do
        subject.should_not_receive(:send_email).with(recipient1) #email is blank
        subject.should_receive(:send_email).with(recipient2)
        subject.call
      end
    end
  end

  describe "send_email" do

    let(:mailer) { double 'mailer' }

    before(:each) do
      subject.stub(:mailer).and_return mailer
    end

    context "with custom_deliver_proc" do
      let(:my_proc) { double 'proc' }

      before { Mailboxer.custom_deliver_proc = my_proc }
      after  { Mailboxer.custom_deliver_proc = nil     }
      it "triggers proc" do
        my_proc.should_receive(:call).with(mailer, mailable, recipient1)
        subject.send :send_email, recipient1
      end
    end

    context "without custom_deliver_proc" do
      let(:email) { double :email }

      it "triggers standard deliver chain" do
        mailer.should_receive(:send_email).with(mailable, recipient1).and_return email
        email.should_receive :deliver

        subject.send :send_email, recipient1
      end
    end
  end

  describe "mailer" do
    let(:recipients) { [] }

    context "mailable is a Message" do
      let(:mailable) { Mailboxer::Motification.new }

      its(:mailer) { should be Mailboxer::MotificationMailer }

      context "with custom mailer" do
        before { Mailboxer.motification_mailer = 'foo' }
        after  { Mailboxer.motification_mailer = nil   }

        its(:mailer) { should eq 'foo' }
      end
    end

    context "mailable is a Motification" do
      let(:mailable) { Mailboxer::Message.new }
      its(:mailer) { should be Mailboxer::MessageMailer }

      context "with custom mailer" do
        before { Mailboxer.message_mailer = 'foo' }
        after  { Mailboxer.message_mailer = nil   }

        its(:mailer) { should eq 'foo' }
      end
    end
  end

  describe "filtered_recipients" do
    context "responds to conversation" do
      let(:conversation) { double 'conversation' }
      let(:mailable)     { double 'mailable', :conversation => conversation }
      before(:each) do
        conversation.should_receive(:has_subscriber?).with(recipient1).and_return false
        conversation.should_receive(:has_subscriber?).with(recipient2).and_return true
      end

      its(:filtered_recipients){ should eq [recipient2] }
    end

    context 'doesnt respond to conversation' do
      let(:mailable) { double 'mailable' }
      its(:filtered_recipients){ should eq recipients }
    end
  end
end
