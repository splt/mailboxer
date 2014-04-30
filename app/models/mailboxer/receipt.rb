class Mailboxer::Receipt < ActiveRecord::Base
  self.table_name = :mailboxer_receipts
  attr_accessible :trashed, :is_read, :deleted if Mailboxer.protected_attributes?

  belongs_to :motification, :class_name => "Mailboxer::Motification", :validate => true, :autosave => true
  belongs_to :receiver, :polymorphic => :true
  belongs_to :message, :class_name => "Mailboxer::Message", :foreign_key => "motification_id"

  validates_presence_of :receiver

  scope :recipient, lambda { |recipient|
    where(:receiver_id => recipient.id,:receiver_type => recipient.class.base_class.to_s)
  }
  #Motifications Scope checks type to be nil, not Motification because of STI behaviour
  #with the primary class (no type is saved)
  scope :motifications_receipts, lambda { joins(:motification).where('mailboxer_motifications.type' => nil) }
  scope :messages_receipts, lambda { joins(:motification).where('mailboxer_motifications.type' => Mailboxer::Message.to_s) }
  scope :motification, lambda { |motification|
    where(:motification_id => motification.id)
  }
  scope :conversation, lambda { |conversation|
    joins(:message).where('mailboxer_motifications.conversation_id' => conversation.id)
  }
  scope :sentbox, lambda { where(:mailbox_type => "sentbox") }
  scope :inbox, lambda { where(:mailbox_type => "inbox") }
  scope :trash, lambda { where(:mailbox_type => "trash", :trashed => true, :deleted => false) }
  scope :not_trash, lambda { where(:trashed => false) }
  scope :deleted, lambda { where(:deleted => true) }
  scope :not_deleted, lambda { where(:deleted => false) }
  scope :is_read, lambda { where(:is_read => "true" ) }
  scope :is_unread, lambda { where(:is_read => "false") }

  after_validation :remove_duplicate_errors
  class << self
    #Marks all the receipts from the relation as read
    def mark_as_read(options={})
      update_receipts({:is_read => true}, options)
    end

    #Marks all the receipts from the relation as unread
    def mark_as_unread(options={})
      update_receipts({:is_read => false}, options)
    end

    #Marks all the receipts from the relation as trashed
    def move_to_trash(options={})
      update_receipts({:trashed => true, :mailbox_type => :trash}, options)
    end

    #Marks all the receipts from the relation as not trashed
    def untrash(options={})
      update_receipts({:trashed => false, :mailbox_type => :inbox}, options)
    end

    #Marks the receipt as deleted
    def mark_as_deleted(options={})
      update_receipts({:deleted => true}, options)
    end

    #Marks the receipt as not deleted
    def mark_as_not_deleted(options={})
      update_receipts({:deleted => false}, options)
    end

    #Moves all the receipts from the relation to inbox
    def move_to_inbox(options={})
      update_receipts({:mailbox_type => :inbox, :trashed => false}, options)
    end

    #Moves all the receipts from the relation to sentbox
    def move_to_sentbox(options={})
      update_receipts({:mailbox_type => :sentbox, :trashed => false}, options)
    end

    #This methods helps to do a update_all with table joins, not currently supported by rails.
    #Acording to the github ticket https://github.com/rails/rails/issues/522 it should be
    #supported with 3.2.
    def update_receipts(updates,options={})
      ids = Array.new
      where(options).each do |rcp|
        ids << rcp.id
      end
      unless ids.empty?
        conditions = [""].concat(ids)
        condition = "id = ? "
        ids.drop(1).each do
          condition << "OR id = ? "
        end
        conditions[0] = condition
        Mailboxer::Receipt.except(:where).except(:joins).where(conditions).update_all(updates)
      end
    end
  end


  #Marks the receipt as deleted
  def mark_as_deleted
    update_attributes(:deleted => true)
  end

  #Marks the receipt as not deleted
  def mark_as_not_deleted
    update_attributes(:deleted => false)
  end

  #Marks the receipt as read
  def mark_as_read
    update_attributes(:is_read => true)
  end

  #Marks the receipt as unread
  def mark_as_unread
    update_attributes(:is_read => false)
  end

  #Marks the receipt as trashed
  def move_to_trash
    update_attributes(:mailbox_type => :trash, :trashed => true)
  end

  #Marks the receipt as not trashed
  def untrash
    update_attributes(:mailbox_type => :inbox, :trashed => false)
  end

  #Moves the receipt to inbox
  def move_to_inbox
    update_attributes(:mailbox_type => :inbox, :trashed => false)
  end

  #Moves the receipt to sentbox
  def move_to_sentbox
    update_attributes(:mailbox_type => :sentbox, :trashed => false)
  end

  #Returns the conversation associated to the receipt if the motification is a Message
  def conversation
    message.conversation if message.is_a? Mailboxer::Message
  end

  #Returns if the participant have read the Motification
  def is_unread?
    !self.is_read
  end

  #Returns if the participant have trashed the Motification
  def is_trashed?
    self.trashed
  end

  protected

  #Removes the duplicate error about not present subject from Conversation if it has been already
  #raised by Message
  def remove_duplicate_errors
    if self.errors["mailboxer_motification.conversation.subject"].present? and self.errors["mailboxer_motification.subject"].present?
      self.errors["mailboxer_motification.conversation.subject"].each do |msg|
        self.errors["mailboxer_motification.conversation.subject"].delete(msg)
      end
    end
  end

  if Mailboxer.search_enabled
    searchable do
      text :subject, :boost => 5 do
        message.subject if message
      end
      text :body do
        message.body if message
      end
      text :search_participants, :boost => 10 do
        conversation.participants.map(&:name)
      end

      integer :receiver_id
      string :mailbox_type
    end
  end
end
