class Mailboxer::MotificationMailer < Mailboxer::BaseMailer
  #Sends and email for indicating a new motification to a receiver.
  #It calls new_motification_email.
  def send_email(motification, receiver)
    new_motification_email(motification, receiver)
  end

  #Sends an email for indicating a new message for the receiver
  def new_motification_email(motification, receiver)
    @motification = motification
    @receiver     = receiver
    set_subject(motification)
    mail :to => receiver.send(Mailboxer.email_method, motification),
         :subject => t('mailboxer.motification_mailer.subject', :subject => @subject),
         :template_name => 'new_motification_email'
  end
end
