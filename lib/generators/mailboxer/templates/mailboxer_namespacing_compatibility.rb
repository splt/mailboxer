class MailboxerNamespacingCompatibility < ActiveRecord::Migration

  def self.up
    rename_table :conversations, :mailboxer_conversations
    rename_table :motifications, :mailboxer_motifications
    rename_table :receipts,      :mailboxer_receipts

    if Rails.version < '4'
      rename_index :mailboxer_motifications, :motifications_on_conversation_id, :mailboxer_motifications_on_conversation_id
      rename_index :mailboxer_receipts,      :receipts_on_motification_id,      :mailboxer_receipts_on_motification_id
    end
  end

  def self.down
    rename_table :mailboxer_conversations, :conversations
    rename_table :mailboxer_motifications, :motifications
    rename_table :mailboxer_receipts,      :receipts

    if Rails.version < '4'
      rename_index :motifications, :mailboxer_motifications_on_conversation_id, :motifications_on_conversation_id
      rename_index :receipts,      :mailboxer_receipts_on_motification_id,      :receipts_on_motification_id
    end
  end
end
