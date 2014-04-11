class Mailboxer::ViewsGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../app/views", __FILE__)

  desc "Copy Mailboxer views into your app"
  def copy_views
    directory('message_mailer', 'app/views/message_mailer')
    directory('motification_mailer', 'app/views/motification_mailer')
  end
end