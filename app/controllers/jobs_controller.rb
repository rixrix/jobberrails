class JobsController < ApplicationController
  require 'digest'

  # GET /jobs
  # GET /jobs.xml
  def index
    @jobs = Job.active(:order => "created_at DESC", :limit => 50)

    respond_to do |format|
      format.html # index.html.erb
      format.atom { render :layout => false }
      format.xml  { render :xml => @jobs }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.xml
  def show
    @job = Job.find(params[:id])
    @job.increment!(:view_count)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @job }
    end
  end
  
  def apply
    @job = Job.find(params[:id])
    
    @job_applicant = @job.job_applicants.build(params[:job_applicant])
    if @job_applicant.save
      session[:applied_id] = @job.id
      Notifier.deliver_somebody_applied(@job.poster_email,@job_applicant.name, @job_applicant.message, @job_applicant.resume.url, @job_applicant.id)
      redirect_to job_url(@job)
    else
      render :action => "show"
    end
  end
  
  def report_spam
    @job = Job.find(params[:id])
    
    if @job.id == session[:reported_id]
      render :text => "<em>Your vote has already been registered. Thanks for voting.</em>"
    else
      @job.increment!(:report_count)
      session[:reported_id] = @job.id
      render :text => "Thank you, your vote was registered and is highly appreciated!"
    end
  end
  
  # GET /jobs/new
  # GET /jobs/new.xml
  def new
    @job = Job.new_default(params[:job])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @job }
    end
  end

  # GET /jobs/1/edit
  def edit
    # validate :token before allowing the poster to edit the job
    # see routes for more info
    if params[:token] and valid_token?(params[:token])
      @job = Job.find(params[:id])
    else
      flash[:notice] = 'Missing or invalid authentication token'
      redirect_to "/"
    end
  end

  def verify
    @job = Job.find(params[:id])
    @already_a_poster = Job.find(:first, :conditions => {:poster_email => @job.poster_email, :verified => 1})

    if request.put?
      @job.auth = Digest::MD5.hexdigest(Time.now.to_s)
      if @already_a_poster
        @job.verified = true
        @job.confirmed = true
        @job.is_active = true

        # notify user that the job ad is now active
        Notifier.deliver_job_posted(@job.poster_email,@job.company, @job.id, @job.auth)
      else
        @job.verified = false
        @job.confirmed = false
        @job.is_active = false

        # notify user and support(admin) that a new job ad is pending for approval
        Notifier.deliver_job_posted_pending(@job.poster_email,@job.company)
        Notifier.deliver_pending_for_approval(@job.company, @job.id, @job.auth)
      end

      @job.save!
      
      redirect_to confirm_job_url(@job)
    end
  end
  
  def confirm
    @job = Job.find(params[:id])
  end

  # POST /jobs
  # POST /jobs.xml
  def create
    @job = Job.new(params[:job])

    respond_to do |format|
      if @job.save
        format.html { redirect_to verify_job_url(@job) }
        format.xml  { render :xml => @job, :status => :created, :location => @job }

      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.xml
  def update
    @job = Job.find(params[:id])
    
    # todo:
    # add permission checking here

    respond_to do |format|
      if @job.update_attributes(params[:job])
        flash[:notice] = 'Job was successfully updated.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.xml
  def destroy
    @job = Job.find(params[:id])
    
    if valid_token?(params[:token])
      @job.destroy
      respond_to do |format|
        flash[:notice] = 'Job was successfully deleted.'
        format.html { redirect_to(jobs_url) }
        format.xml  { head :ok }
      end
    else
        flash[:notice] = 'Missing or invalid authentication token'
        redirect_to "/"
    end
  end

  # Activates a job ad.
  # Only admin can activate a job ad of time job poster.
  def activate
    @job = Job.find(params[:id])

    if @job
      if (!already_a_member?(@job.poster_email) and session[:admin]) or already_a_member?(@job.poster_email)
        @job.auth == params[:token]
        @job.verified = true
        @job.confirmed = true
        @job.is_active = true
        flash[:notice] = 'Job was successfully activated.' unless @job.save!
        Notifier.deliver_approved_job_ad(@job.poster_email, @job.id, @job.auth)
        redirect_to "/jobs/#{params[:id]}"
      else
        redirect_to admin_url
      end
    else
      redirect_to admin_url
    end
  end

  # Deactivates a job
  def deactivate
    @job = Job.find(params[:id])
    return false unless @job and @job.auth == params[:token]
    @job.is_active = false
    @job.save!
    redirect_to(jobs_url)
  end

  protected
  def already_a_member?(email)
    @already_a_member = Job.find(:first, :conditions => {:poster_email => email, :verified => 1})
    return false unless @already_a_member
  end
  
  def valid_token?(token)
    @token_found = Job.find(:first, :conditions => {:auth => token})
    return true unless !@token_found
  end
end
