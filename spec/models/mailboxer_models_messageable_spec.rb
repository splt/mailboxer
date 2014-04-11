require 'spec_helper'

describe "Mailboxer::Models::Messageable through User" do

  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
  end

  it "should have a mailbox" do
    assert @entity1.mailbox
  end

  it "should be able to send a message" do
    assert @entity1.send_message(@entity2,"Body","Subject")
  end

  it "should be able to reply to sender" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    assert @entity2.reply_to_sender(@receipt,"Reply body")
  end

  it "should be able to reply to all" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    assert @entity2.reply_to_all(@receipt,"Reply body")
  end



  it "should be able to unread an owned Mailboxer::Receipt (mark as unread)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@receipt)
    @receipt.is_read.should==false
  end

  it "should be able to read an owned Mailboxer::Receipt (mark as read)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@receipt)
    @entity1.mark_as_read(@receipt)
    @receipt.is_read.should==true
  end

  it "should not be able to unread a not owned Mailboxer::Receipt (mark as unread)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.is_read.should==true
    @entity2.mark_as_unread(@receipt) #Should not change
    @receipt.is_read.should==true
  end

  it "should not be able to read a not owned Mailboxer::Receipt (mark as read)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@receipt) #From read to unread
    @entity2.mark_as_read(@receipt) #Should not change
    @receipt.is_read.should==false
  end

  it "should be able to trash an owned Mailboxer::Receipt" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.trashed.should==false
    @entity1.trash(@receipt)
    @receipt.trashed.should==true
  end

  it "should be able to untrash an owned Mailboxer::Receipt" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.trashed.should==false
    @entity1.trash(@receipt)
    @entity1.untrash(@receipt)
    @receipt.trashed.should==false
  end

  it "should not be able to trash a not owned Mailboxer::Receipt" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.trashed.should==false
    @entity2.trash(@receipt) #Should not change
    @receipt.trashed.should==false
  end

  it "should not be able to untrash a not owned Mailboxer::Receipt" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @receipt.trashed.should==false
    @entity1.trash(@receipt) #From read to unread
    @entity2.untrash(@receipt) #Should not change
    @receipt.trashed.should==true
  end



  it "should be able to unread an owned Message (mark as unread)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@message)
    @message.receipt_for(@entity1).first.is_read.should==false
  end

  it "should be able to read an owned Message (mark as read)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@message)
    @entity1.mark_as_read(@message)
    @message.receipt_for(@entity1).first.is_read.should==true
  end

  it "should not be able to unread a not owned Message (mark as unread)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.is_read.should==true
    @entity2.mark_as_unread(@message) #Should not change
    @message.receipt_for(@entity1).first.is_read.should==true
  end

  it "should not be able to read a not owned Message (mark as read)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@message) #From read to unread
    @entity2.mark_as_read(@message) #Should not change
    @message.receipt_for(@entity1).first.is_read.should==false
  end

  it "should be able to trash an owned Message" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.trashed.should==false
    @entity1.trash(@message)
    @message.receipt_for(@entity1).first.trashed.should==true
  end

  it "should be able to untrash an owned Message" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.trashed.should==false
    @entity1.trash(@message)
    @entity1.untrash(@message)
    @message.receipt_for(@entity1).first.trashed.should==false
  end

  it "should not be able to trash a not owned Message" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.trashed.should==false
    @entity2.trash(@message) #Should not change
    @message.receipt_for(@entity1).first.trashed.should==false
  end

  it "should not be able to untrash a not owned Message" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @message = @receipt.message
    @receipt.trashed.should==false
    @entity1.trash(@message) #From read to unread
    @entity2.untrash(@message) #Should not change
    @message.receipt_for(@entity1).first.trashed.should==true
  end



  it "should be able to unread an owned Motification (mark as unread)" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.is_read.should==false
    @entity1.mark_as_read(@motification)
    @entity1.mark_as_unread(@motification)
    @motification.receipt_for(@entity1).first.is_read.should==false
  end

  it "should be able to read an owned Motification (mark as read)" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.is_read.should==false
    @entity1.mark_as_read(@motification)
    @motification.receipt_for(@entity1).first.is_read.should==true
  end

  it "should not be able to unread a not owned Motification (mark as unread)" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.is_read.should==false
    @entity1.mark_as_read(@motification)
    @entity2.mark_as_unread(@motification)
    @motification.receipt_for(@entity1).first.is_read.should==true
  end

  it "should not be able to read a not owned Motification (mark as read)" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.is_read.should==false
    @entity2.mark_as_read(@motification)
    @motification.receipt_for(@entity1).first.is_read.should==false
  end

  it "should be able to trash an owned Motification" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.trashed.should==false
    @entity1.trash(@motification)
    @motification.receipt_for(@entity1).first.trashed.should==true
  end

  it "should be able to untrash an owned Motification" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.trashed.should==false
    @entity1.trash(@motification)
    @entity1.untrash(@motification)
    @motification.receipt_for(@entity1).first.trashed.should==false
  end

  it "should not be able to trash a not owned Motification" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.trashed.should==false
    @entity2.trash(@motification)
    @motification.receipt_for(@entity1).first.trashed.should==false
  end

  it "should not be able to untrash a not owned Motification" do
    @receipt = @entity1.notify("Subject","Body")
    @motification = @receipt.motification
    @receipt.trashed.should==false
    @entity1.trash(@motification)
    @entity2.untrash(@motification)
    @motification.receipt_for(@entity1).first.trashed.should==true
  end



  it "should be able to unread an owned Conversation (mark as unread)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@conversation)
    @conversation.receipts_for(@entity1).first.is_read.should==false
  end

  it "should be able to read an owned Conversation (mark as read)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@conversation)
    @entity1.mark_as_read(@conversation)
    @conversation.receipts_for(@entity1).first.is_read.should==true
  end

  it "should not be able to unread a not owned Conversation (mark as unread)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.is_read.should==true
    @entity2.mark_as_unread(@conversation)
    @conversation.receipts_for(@entity1).first.is_read.should==true
  end

  it "should not be able to read a not owned Conversation (mark as read)" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.is_read.should==true
    @entity1.mark_as_unread(@conversation)
    @entity2.mark_as_read(@conversation)
    @conversation.receipts_for(@entity1).first.is_read.should==false
  end

  it "should be able to trash an owned Conversation" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.trashed.should==false
    @entity1.trash(@conversation)
    @conversation.receipts_for(@entity1).first.trashed.should==true
  end

  it "should be able to untrash an owned Conversation" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.trashed.should==false
    @entity1.trash(@conversation)
    @entity1.untrash(@conversation)
    @conversation.receipts_for(@entity1).first.trashed.should==false
  end

  it "should not be able to trash a not owned Conversation" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.trashed.should==false
    @entity2.trash(@conversation)
    @conversation.receipts_for(@entity1).first.trashed.should==false
  end

  it "should not be able to untrash a not owned Conversation" do
    @receipt = @entity1.send_message(@entity2,"Body","Subject")
    @conversation = @receipt.conversation
    @receipt.trashed.should==false
    @entity1.trash(@conversation)
    @entity2.untrash(@conversation)
    @conversation.receipts_for(@entity1).first.trashed.should==true
  end

  it "should be able to read attachment" do
    @receipt = @entity1.send_message(@entity2, "Body", "Subject", nil, File.open('spec/testfile.txt'))
    @conversation = @receipt.conversation
    @conversation.messages.first.attachment_identifier.should=='testfile.txt'
  end

  it "should be the same message time as passed" do
    message_time = 5.days.ago
    receipt = @entity1.send_message(@entity2, "Body", "Subject", nil, nil, message_time)
    # We're going to compare the string representation, because ActiveSupport::TimeWithZone
    # has microsecond precision in ruby, but some databases don't support this level of precision.
    expected = message_time.utc.to_s
    receipt.message.created_at.utc.to_s.should == expected
    receipt.message.updated_at.utc.to_s.should == expected
    receipt.message.conversation.created_at.utc.to_s.should == expected
    receipt.message.conversation.updated_at.utc.to_s.should == expected
  end

end
