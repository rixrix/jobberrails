class Notifier < ActionMailer::Base
  

  def job_posted(recipient, company, id, auth, sent_at = Time.now)
    subject    "#{AppConfig.site_name} - Thanks for Posting"
    recipients recipient
    from       AppConfig.from_email
    sent_on    sent_at
    content_type "multipart/alternative"
    
    part :content_type => "text/plain",
         :body =>  render_message("job_posted", 
         :company => company, :id => id, :auth => auth)

  end

  def somebody_applied(recipient, name, message, filename, id, sent_at = Time.now)
    subject    "#{AppConfig.site_name} - New Job Applicant"
    recipients recipient
    from       AppConfig.from_email
    sent_on    sent_at
    content_type "multipart/alternative"
    
    attachment :context_type => 'application/octet-stream',
               :body => File.read("./public#{filename}"),
               :filename => File.basename("./public#{filename}")

    part :content_type => "text/plain",
         :body =>  render_message("somebody_applied",
         :name => name, :message => message)
  end

  # Sends an email to the job poster about pending approval from admin
  def job_posted_pending(recipient, company, sent_at = Time.now)
    subject    "#{AppConfig.site_name} - Thanks for Posting"
    recipients recipient
    from       AppConfig.from_email
    sent_on    sent_at
    content_type "multipart/alternative"

    part :content_type => "text/plain",
      :body =>  render_message("job_posted_pending", :company => company)
  end

  # Sends an email to the admin about a new job ad with pending approval
  def pending_for_approval(company, id, auth, sent_at = Time.now)
    subject    "Pending for Approval #{company}"
    recipients AppConfig.support_email
    from       "#{AppConfig.patrol_email}"
    sent_on    sent_at
    content_type "multipart/alternative"

    part :content_type => "text/plain",
      :body =>  render_message("pending_for_approval", :company => company, :id => id, :auth => auth)
  end

  # notify the job poster that the job was approved
  def approved_job_ad(email,id, auth, sent_at = Time.now)
    subject    "Approved - Job Advertisement"
    recipients "#{email}"
    from       "#{AppConfig.support_email}"
    sent_on    sent_at
    content_type "multipart/alternative"

    part :content_type => "text/plain",
      :body =>  render_message("approved_job_ad", :email => email, :id => id, :auth => auth)
  end
end
