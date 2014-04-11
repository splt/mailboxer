require 'spec_helper'

describe Mailboxer::Message do
  
  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @receipt1 = @entity1.send_message(@entity2,"Body","Subject")
    @receipt2 = @entity2.reply_to_all(@receipt1,"Reply body 1")
    @receipt3 = @entity1.reply_to_all(@receipt2,"Reply body 2")
    @receipt4 = @entity2.reply_to_all(@receipt3,"Reply body 3")
    @message1 = @receipt1.motification
    @message4 = @receipt4.motification
    @conversation = @message1.conversation
  end  
  
  it "should have right recipients" do
  	@receipt1.motification.recipients.count.should==2
  	@receipt2.motification.recipients.count.should==2
  	@receipt3.motification.recipients.count.should==2
  	@receipt4.motification.recipients.count.should==2      
  end

  it "should be able to be marked as deleted" do
    @receipt1.deleted.should==false
    @message1.mark_as_deleted @entity1
    @message1.is_deleted?(@entity1).should==true
  end
    
end
