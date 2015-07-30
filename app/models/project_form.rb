class ProjectForm
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  
  attribute :parent_id, Integer
  attribute :client_id, Integer
  attribute :name, String
  attribute :account, String
  attribute :description, String
  attribute :clockable, Boolean
  attribute :billable, Boolean
  attribute :flat_rate, Boolean
  attribute :archived, Boolean
  attribute :pivotal_id, Boolean
  attribute :repositories_attributes, Hash
  attribute :rates_attributes, Hash
  
  attr_accessor :project, :form_options
#  attr_accessor :repositories, :rates #try to delete

  def self.find(id)
    project_form = self.new
    project_form.project = Project.find(id)
    project_form.attributes = project_form.project.attributes
    project_form
  end
  
  def set_defaults
    @project = Project.new
    @project.repositories.new
    @project.rates.new
    self.attributes = project_defaults
  end
  
  def append_new_rate
    @project.rates.new
  end
  
  def save
    @project ||= Project.new
    @project.assign_attributes(project_params)

    assign_repositories
    assign_rates

    @project.save
      
    unless project.errors.blank?
      @errors = @project.errors
    end


    errors.blank?
  end
  
  private
      
  def assign_repositories
    if @repositories_attributes
      @repositories_attributes.values.each do |ra|
        if ra["id"]
            repo = @project.repositories.find(ra["id"])
            ind = @project.repositories.index(repo) 
          if ra["url"].blank? || ra["_destroy"] == "1"
            @project.repositories[ind].mark_for_destruction
          else
            @project.repositories[ind].url =  ra["url"]
          end
        else
          unless ra["url"].blank? || ra["_destroy"] == "1"
            @project.repositories.new(url: ra["url"])
          end
        end
      end
    end
    @project.repositories
  end
  
  def assign_rates
    if @rates_attributes
      @rates_attributes.values.each do |ra|
        if ra["id"]
          rate = @project.rates.find(ra["id"])
          ind = @project.rates.index(rate)
          if ra["_destroy"] == "1" || ( ra["name"].blank? && ra["amount"].blank? )
            @project.rates[ind].mark_for_destruction
          else
            @project.rates[ind].assign_attributes(name: ra["name"], amount: ra["amount"])
          end
        else
          unless ra["_destroy"] == "1" || ( ra["name"].blank? && ra["amount"].blank? )
            @project.rates.new(name: ra["name"], amount: ra["amount"])
          end
        end
      end
    end
  end
      
  def project_params
    {
      parent_id: @parent_id,
      client_id: @client_id,
      name: @name,
      account: @account,
      description: @description,
      clockable: @clockable,
      billable: @billable,
      flat_rate: @flat_rate,
      archived: @archived,
      pivotal_id: @pivotal
      }
  end

  def project_defaults
    {
      clockable: false,
      billable: true,
      flat_rate: false,
      archived: false,
      }
  end
end
