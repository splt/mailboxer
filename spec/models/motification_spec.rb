require 'spec_helper'

describe Mailboxer::Motification do

  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @entity3 = FactoryGirl.create(:user)
  end

  it { should validate_presence_of :subject }
  it { should validate_presence_of :body }

  it { should ensure_length_of(:subject).is_at_most(Mailboxer.subject_max_length) }
  it { should ensure_length_of(:body).is_at_most(Mailboxer.body_max_length) }

  it "should notify one user" do
    @entity1.notify("Subject", "Body")

    #Check getting ALL receipts
    @entity1.mailbox.receipts.size.should==1
    receipt      = @entity1.mailbox.receipts.first
    motification = receipt.motification
    motification.subject.should=="Subject"
    motification.body.should=="Body"

    #Check getting NOTIFICATION receipts only
    @entity1.mailbox.motifications.size.should==1
    motification = @entity1.mailbox.motifications.first
    motification.subject.should=="Subject"
    motification.body.should=="Body"
  end

  it "should be unread by default" do
    @entity1.notify("Subject", "Body")
    @entity1.mailbox.receipts.size.should==1
    motification = @entity1.mailbox.receipts.first.motification
    motification.should be_is_unread(@entity1)
  end

  it "should be able to marked as read" do
    @entity1.notify("Subject", "Body")
    @entity1.mailbox.receipts.size.should==1
    motification = @entity1.mailbox.receipts.first.motification
    motification.mark_as_read(@entity1)
    motification.should be_is_read(@entity1)
  end

  it "should notify several users" do
    recipients = Set.new [@entity1,@entity2,@entity3]
    Mailboxer::Motification.notify_all(recipients,"Subject","Body")
    #Check getting ALL receipts
    @entity1.mailbox.receipts.size.should==1
    receipt      = @entity1.mailbox.receipts.first
    motification = receipt.motification
    motification.subject.should=="Subject"
    motification.body.should=="Body"
    @entity2.mailbox.receipts.size.should==1
    receipt      = @entity2.mailbox.receipts.first
    motification = receipt.motification
    motification.subject.should=="Subject"
    motification.body.should=="Body"
    @entity3.mailbox.receipts.size.should==1
    receipt      = @entity3.mailbox.receipts.first
    motification = receipt.motification
    motification.subject.should=="Subject"
    motification.body.should=="Body"

    #Check getting NOTIFICATION receipts only
    @entity1.mailbox.motifications.size.should==1
    motification = @entity1.mailbox.motifications.first
    motification.subject.should=="Subject"
    motification.body.should=="Body"
    @entity2.mailbox.motifications.size.should==1
    motification = @entity2.mailbox.motifications.first
    motification.subject.should=="Subject"
    motification.body.should=="Body"
    @entity3.mailbox.motifications.size.should==1
    motification = @entity3.mailbox.motifications.first
    motification.subject.should=="Subject"
    motification.body.should=="Body"

  end

  it "should notify a single recipient" do
    Mailboxer::Motification.notify_all(@entity1,"Subject","Body")

    #Check getting ALL receipts
    @entity1.mailbox.receipts.size.should==1
    receipt      = @entity1.mailbox.receipts.first
    motification = receipt.motification
    motification.subject.should=="Subject"
    motification.body.should=="Body"

    #Check getting NOTIFICATION receipts only
    @entity1.mailbox.motifications.size.should==1
    motification = @entity1.mailbox.motifications.first
    motification.subject.should=="Subject"
    motification.body.should=="Body"
  end

  describe "scopes" do
    let(:scope_user) { FactoryGirl.create(:user) }
    let!(:motification) { scope_user.notify("Body", "Subject").motification }

    describe ".unread" do
      it "finds unread motifications" do
        unread_motification = scope_user.notify("Body", "Subject").motification
        motification.mark_as_read(scope_user)
        Mailboxer::Motification.unread.last.should == unread_motification
      end
    end

    describe ".expired" do
      it "finds expired motifications" do
        motification.update_attributes(expires: 1.day.ago)
        scope_user.mailbox.motifications.expired.count.should eq(1)
      end
    end

    describe ".unexpired" do
      it "finds unexpired motifications" do
        motification.update_attributes(expires: 1.day.from_now)
        scope_user.mailbox.motifications.unexpired.count.should eq(1)
      end
    end
  end

  describe "#expire" do
    subject { described_class.new }

    describe "when the motification is already expired" do
      before do
        subject.stub(:expired? => true)
      end
      it 'should not update the expires attribute' do
        subject.should_not_receive :expires=
        subject.should_not_receive :save
        subject.expire
      end
    end

    describe "when the motification is not expired" do
      let(:now) { Time.now }
      let(:one_second_ago) { now - 1.second }
      before do
        Time.stub(:now => now)
        subject.stub(:expired? => false)
      end
      it 'should update the expires attribute' do
        subject.should_receive(:expires=).with(one_second_ago)
        subject.expire
      end
      it 'should not save the record' do
        subject.should_not_receive :save
        subject.expire
      end
    end

  end

  describe "#expire!" do
    subject { described_class.new }

    describe "when the motification is already expired" do
      before do
        subject.stub(:expired? => true)
      end
      it 'should not call expire' do
        subject.should_not_receive :expire
        subject.should_not_receive :save
        subject.expire!
      end
    end

    describe "when the motification is not expired" do
      let(:now) { Time.now }
      let(:one_second_ago) { now - 1.second }
      before do
        Time.stub(:now => now)
        subject.stub(:expired? => false)
      end
      it 'should call expire' do
        subject.should_receive(:expire)
        subject.expire!
      end
      it 'should save the record' do
        subject.should_receive :save
        subject.expire!
      end
    end

  end

  describe "#expired?" do
    subject { described_class.new }
    context "when the expiration date is in the past" do
      before { subject.stub(:expires => Time.now - 1.second) }
      it 'should be expired' do
        subject.expired?.should be_true
      end
    end

    context "when the expiration date is now" do
      before {
        time = Time.now
        Time.stub(:now => time)
        subject.stub(:expires => time)
      }

      it 'should not be expired' do
        subject.expired?.should be_false
      end
    end

    context "when the expiration date is in the future" do
      before { subject.stub(:expires => Time.now + 1.second) }
      it 'should not be expired' do
        subject.expired?.should be_false
      end
    end

    context "when the expiration date is not set" do
      before {subject.stub(:expires => nil)}
      it 'should not be expired' do
        subject.expired?.should be_false
      end
    end

  end

end
