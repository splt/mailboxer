require 'spec_helper'

describe Mailboxer::Receipt do
  
  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @mail1 = @entity1.send_message(@entity2,"Body","Subject")   
  end
  
  it "should belong to a message" do
    assert @mail1.motification
  end
  
  it "should belong to a conversation" do
    assert @mail1.conversation    
  end
  
  it "should be able to be marked as unread" do
    @mail1.is_read.should==true
    @mail1.mark_as_unread
    @mail1.is_read.should==false
  end
  
  it "should be able to be marked as read" do
    @mail1.is_read.should==true
    @mail1.mark_as_unread
    @mail1.mark_as_read
    @mail1.is_read.should==true    
  end

  it "should be able to be marked as deleted" do
    @mail1.deleted.should==false
    @mail1.mark_as_deleted
    @mail1.deleted.should==true
  end

  it "should be able to be marked as not deleted" do
    @mail1.deleted=true
    @mail1.mark_as_not_deleted
    @mail1.deleted.should==false
  end

  context "STI models" do
    before do
      @entity3 = FactoryGirl.create(:user)
      @entity4 = FactoryGirl.create(:user)
      @mail2 = @entity3.send_message(@entity4, "Body", "Subject")
    end
	
    it "should refer to the correct base class" do
      @mail2.receiver_type.should == @entity3.class.base_class.to_s
    end
  end
  
end
