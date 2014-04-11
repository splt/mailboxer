class Duck < ActiveRecord::Base
  acts_as_messageable
  def mailboxer_email(object)
    case object
    when Mailboxer::Message
      return nil
    when Mailboxer::Motification
      return email
    end
  end
end
