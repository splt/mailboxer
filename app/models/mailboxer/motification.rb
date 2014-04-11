class Mailboxer::Motification < ActiveRecord::Base
  self.table_name = :mailboxer_motifications

  attr_accessor :recipients
  attr_accessible :body, :subject, :global, :expires if Mailboxer.protected_attributes?

  belongs_to :sender, :polymorphic => :true
  belongs_to :notified_object, :polymorphic => :true
  has_many :receipts, :dependent => :destroy, :class_name => "Mailboxer::Receipt"

  validates :subject, :presence => true,
                      :length => { :maximum => Mailboxer.subject_max_length }
  validates :body,    :presence => true,
                      :length => { :maximum => Mailboxer.body_max_length }

  scope :recipient, lambda { |recipient|
    joins(:receipts).where('mailboxer_receipts.receiver_id' => recipient.id,'mailboxer_receipts.receiver_type' => recipient.class.base_class.to_s)
  }
  scope :with_object, lambda { |obj|
    where('notified_object_id' => obj.id,'notified_object_type' => obj.class.to_s)
  }
  scope :not_trashed, lambda {
    joins(:receipts).where('mailboxer_receipts.trashed' => false)
  }
  scope :unread,  lambda {
    joins(:receipts).where('mailboxer_receipts.is_read' => false)
  }
  scope :global, lambda { where(:global => true) }
  scope :expired, lambda { where("mailboxer_motifications.expires < ?", Time.now) }
  scope :unexpired, lambda {
    where("mailboxer_motifications.expires is NULL OR mailboxer_motifications.expires > ?", Time.now)
  }

  class << self
    #Sends a Motification to all the recipients
    def notify_all(recipients,subject,body,obj = nil,sanitize_text = true,motification_code=nil,send_mail=true)
      motification = Mailboxer::Motification.new({:body => body, :subject => subject})
      motification.recipients        = Array(recipients).uniq
      motification.notified_object   = obj               if obj.present?
      motification.motification_code = motification_code if motification_code.present?
      motification.deliver sanitize_text, send_mail
    end

    #Takes a +Receipt+ or an +Array+ of them and returns +true+ if the delivery was
    #successful or +false+ if some error raised
    def successful_delivery? receipts
      case receipts
      when Mailboxer::Receipt
        receipts.valid?
        receipts.errors.empty?
      when Array
        receipts.each(&:valid?)
        receipts.all? { |t| t.errors.empty? }
      else
        false
      end
    end
  end

  def expired?
    self.expires.present? && (self.expires < Time.now)
  end

  def expire!
    unless self.expired?
      self.expire
      self.save
    end
  end

  def expire
    unless self.expired?
      self.expires = Time.now - 1.second
    end
  end

  #Delivers a Motification. USE NOT RECOMENDED.
  #Use Mailboxer::Models::Message.notify and Motification.notify_all instead.
  def deliver(should_clean = true, send_mail = true)
    clean if should_clean
    temp_receipts = Array.new

    #Receiver receipts
    self.recipients.each do |r|
      temp_receipts << build_receipt(r, nil, false)
    end

    if temp_receipts.all?(&:valid?)
      temp_receipts.each(&:save!)   #Save receipts
      Mailboxer::MailDispatcher.new(self, recipients).call if send_mail
      self.recipients = nil
    end

    return temp_receipts if temp_receipts.size > 1
    temp_receipts.first
  end

  #Returns the recipients of the Motification
  def recipients
    if @recipients.blank?
      recipients_array = Array.new
      self.receipts.each do |receipt|
        recipients_array << receipt.receiver
      end

      recipients_array
    else
      @recipients
    end
  end

  #Returns the receipt for the participant
  def receipt_for(participant)
    Mailboxer::Receipt.motification(self).recipient(participant)
  end

  #Returns the receipt for the participant. Alias for receipt_for(participant)
  def receipts_for(participant)
    receipt_for(participant)
  end

  #Returns if the participant have read the Motification
  def is_unread?(participant)
    return false if participant.nil?
    !self.receipt_for(participant).first.is_read
  end

  def is_read?(participant)
    !self.is_unread?(participant)
  end

  #Returns if the participant have trashed the Motification
  def is_trashed?(participant)
    return false if participant.nil?
    self.receipt_for(participant).first.trashed
  end

  #Returns if the participant have deleted the Motification
  def is_deleted?(participant)
    return false if participant.nil?
    return self.receipt_for(participant).first.deleted
  end

  #Mark the motification as read
  def mark_as_read(participant)
    return if participant.nil?
    self.receipt_for(participant).mark_as_read
  end

  #Mark the motification as unread
  def mark_as_unread(participant)
    return if participant.nil?
    self.receipt_for(participant).mark_as_unread
  end

  #Move the motification to the trash
  def move_to_trash(participant)
    return if participant.nil?
    self.receipt_for(participant).move_to_trash
  end

  #Takes the motification out of the trash
  def untrash(participant)
    return if participant.nil?
    self.receipt_for(participant).untrash
  end

  #Mark the motification as deleted for one of the participant
  def mark_as_deleted(participant)
    return if participant.nil?
    return self.receipt_for(participant).mark_as_deleted
  end

  #Sanitizes the body and subject
  def clean
    self.subject = sanitize(subject) if subject
    self.body    = sanitize(body)
  end

  #Returns notified_object. DEPRECATED
  def object
    warn "DEPRECATION WARNING: use 'notify_object' instead of 'object' to get the object associated with the Motification"
    notified_object
  end

  def sanitize(text)
    ::Mailboxer::Cleaner.instance.sanitize(text)
  end

  private

  def build_receipt(receiver, mailbox_type, is_read = false)
    Mailboxer::Receipt.new.tap do |receipt|
      receipt.motification = self
      receipt.is_read = is_read
      receipt.receiver = receiver
      receipt.mailbox_type = mailbox_type
    end
  end

end
