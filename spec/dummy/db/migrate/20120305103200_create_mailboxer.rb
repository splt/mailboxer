class CreateMailboxer < ActiveRecord::Migration
  def self.up    
  #Tables
  	#Conversations
    create_table :mailboxer_conversations do |t|
      t.column :subject, :string, :default => ""
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end    
  	#Receipts
    create_table :mailboxer_receipts do |t|
      t.references :receiver, :polymorphic => true
      t.column :motification_id, :integer, :null => false
      t.column :is_read, :boolean, :default => false
      t.column :trashed, :boolean, :default => false
      t.column :deleted, :boolean, :default => false
      t.column :mailbox_type, :string, :limit => 25
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end    
  	#Motifications and Messages
    create_table :mailboxer_motifications do |t|
      t.column :type, :string
      t.column :body, :text
      t.column :subject, :string, :default => ""
      t.references :sender, :polymorphic => true
      t.references :notified_object, :polymorphic => true
      t.string :motification_code, :default => nil
      t.column :conversation_id, :integer
      t.column :draft, :boolean, :default => false
      t.column :attachment, :string
      t.column :updated_at, :datetime, :null => false
      t.column :created_at, :datetime, :null => false
      t.boolean :global, :default => false
      t.datetime :expires
    end    
    
    
  #Indexes
  	#Conversations
  	#Receipts
  	add_index "mailboxer_receipts","motification_id"

  	#Messages  
  	add_index "mailboxer_motifications","conversation_id"
  
  #Foreign keys    
  	#Conversations
  	#Receipts
  	add_foreign_key "mailboxer_receipts", "mailboxer_motifications", :name => "receipts_on_motification_id", :column => "motification_id"
  	#Messages  
  	add_foreign_key "mailboxer_motifications", "mailboxer_conversations", :name => "motifications_on_conversation_id", :column => "conversation_id"
  end
  
  def self.down
  #Tables  	
  	remove_foreign_key "mailboxer_receipts", :name => "receipts_on_motification_id"
  	remove_foreign_key "mailboxer_motifications", :name => "motifications_on_conversation_id"
  	
  #Indexes
    drop_table :mailboxer_receipts
    drop_table :mailboxer_conversations
    drop_table :mailboxer_motifications
  end
end
