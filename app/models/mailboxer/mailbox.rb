class Mailboxer::Mailbox
  attr_accessor :type
  attr_reader :messageable

  #Initializer method
  def initialize(messageable)
    @messageable = messageable
  end

  #Returns the motifications for the messageable
  def motifications(options = {})
    #:type => nil is a hack not to give Messages as Motifications
    notifs = Mailboxer::Motification.recipient(@messageable).where(:type => nil).order("mailboxer_motifications.created_at DESC")
    if (options[:read].present? and options[:read]==false) or (options[:unread].present? and options[:unread]==true)
      notifs = notifs.unread
    end

    notifs
  end

  #Returns the conversations for the messageable
  #
  #Options
  #
  #* :mailbox_type
  #  * "inbox"
  #  * "sentbox"
  #  * "trash"
  #
  #* :read=false
  #* :unread=true
  #
  def conversations(options = {})
    conv = Mailboxer::Conversation.participant(@messageable)

    if options[:mailbox_type].present?
      case options[:mailbox_type]
      when 'inbox'
        conv = Mailboxer::Conversation.inbox(@messageable)
      when 'sentbox'
        conv = Mailboxer::Conversation.sentbox(@messageable)
      when 'trash'
        conv = Mailboxer::Conversation.trash(@messageable)
      when  'not_trash'
        conv = Mailboxer::Conversation.not_trash(@messageable)
      end
    end

    if (options.has_key?(:read) && options[:read]==false) || (options.has_key?(:unread) && options[:unread]==true)
      conv = conv.unread(@messageable)
    end

    conv
  end

  #Returns the conversations in the inbox of messageable
  #
  #Same as conversations({:mailbox_type => 'inbox'})
  def inbox(options={})
    options = options.merge(:mailbox_type => 'inbox')
    self.conversations(options)
  end

  #Returns the conversations in the sentbox of messageable
  #
  #Same as conversations({:mailbox_type => 'sentbox'})
  def sentbox(options={})
    options = options.merge(:mailbox_type => 'sentbox')
    self.conversations(options)
  end

  #Returns the conversations in the trash of messageable
  #
  #Same as conversations({:mailbox_type => 'trash'})
  def trash(options={})
    options = options.merge(:mailbox_type => 'trash')
    self.conversations(options)
  end

  #Returns all the receipts of messageable, from Messages and Motifications
  def receipts(options = {})
    Mailboxer::Receipt.where(options).recipient(@messageable)
  end

  #Deletes all the messages in the trash of messageable. NOT IMPLEMENTED.
  def empty_trash(options = {})
    #TODO
    false
  end

  #Returns if messageable is a participant of conversation
  def has_conversation?(conversation)
    conversation.is_participant?(@messageable)
  end

  #Returns true if messageable has at least one trashed message of the conversation
  def is_trashed?(conversation)
    conversation.is_trashed?(@messageable)
  end

  #Returns true if messageable has trashed all the messages of the conversation
  def is_completely_trashed?(conversation)
    conversation.is_completely_trashed?(@messageable)
  end

  #Returns the receipts of object for messageable as a ActiveRecord::Relation
  #
  #Object can be:
  #* A Message
  #* A Motification
  #* A Conversation
  #
  #If object isn't one of the above, a nil will be returned
  def receipts_for(object)
    case object
    when Mailboxer::Message, Mailboxer::Motification
      object.receipt_for(@messageable)
    when Mailboxer::Conversation
      object.receipts_for(@messageable)
    end
  end
end
