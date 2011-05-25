class Coder < ActiveRecord::Base
  has_many :commits
  has_many :projects, :through => :commits
  has_many :orgs, :through => :commits    
  validates_uniqueness_of :login
  
  # given a coder name, goto github and grab the user details and create a new coder
  #
  # @param name The username of the coder i.e. sferik
  # @return Github user object or error
  # @example Coder.new.get_details("sferik")
  
  def get_details(name)
    begin
      coder = Octokit.user(name) 
    rescue
      return false, "We had a problem finding that user"
    else
      return Coder.create!(coder)
    end
  end

  # given a coder name, find and return it or goto github and grab the user details and return a new coder
  #
  # @param name The username of the coder i.e. sferik
  # @return Github user object or error
  # @example Coder.new.get_details("sferik")
  
  def find_or_create(name)
    coder = Coder.where(:login => name).first
    !coder.blank? ? coder : self.get_details(name)
  end
  
  # mongo's not so great about has many through, so we'll have to pull them manually
  def projects
    projects = []
    self.commits.distinct(:project_id).each {|x| projects << Project.where(:_id => x).first }
    projects
  end
  


end
