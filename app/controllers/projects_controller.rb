class ProjectsController < ApplicationController
  before_filter :require_admin!

  # GET /projects
  def index
    @root_project = Project.root
  end

  # GET /projects/1
  def show
    @project = Project.find(params[:id])
    @repos = Repository.where(project_id: params[:id])
    @active_users = User.active
  end

  # GET /projects/new
  def new
    @project = Project.new
    @project.rates.build
    @repo = Repository.new(project_id: @project.id)
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
    @repos = @project.repositories
    @project.rates.build if @project.parent == Project.root
  end

  # POST /projects
  def create
    @project = Project.new(project_params)
    @repo = Repository.create(url: params[:project][:github_url])
    @repo.project = @project
    # @repo.project_id = @project.id
    @repo.save
    if @project.save && @repo.save
      flash[:notice] = 'Project was successfully created.'
      expire_fragment "picker_node_#{@project.id}"
      expire_fragment "project_picker"
      redirect_to(@project)
    else
      @project.rates.build
      render :action => "new"
    end
  end

  # PUT /projects/1
  def update
    @project = Project.find(params[:id])
    @repos = @project.repositories.first
    @repos.url = params[:project][:github_url]
    @repos.save
    if @project.update(project_params)
      expire_fragment "picker_node_#{@project.id}"
      expire_fragment "project_picker"
      flash[:notice] = 'Project was successfully updated.'
      redirect_to :action => "index"
    else
      @project.rates.build
      render :action => "edit"
    end
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "Illegal self referential or circular parent assignment"
    redirect_to(@project)
  end

  # DELETE /projects/1
  def destroy
    @project = Project.find(params[:id])
    @id = params[:id]
    @repos = @project.repositories
    @repos.each { |repo| repo.destroy }
    @project.destroy

    expire_fragment "project_picker"

    respond_to do |format|
      format.html { redirect_to projects_path }
      format.js
    end
  end

  private

  def project_params
    params.
    require(:project).
    permit(:name,
      :account,
      :description,
      :clockable,
      :billable,
      :flat_rate,
      :archived,
      :pivotal_id,
      {:rates_attributes => [:id, :name, :amount, :_destroy]},
      :client_id,
      :parent_id)
  end

end
