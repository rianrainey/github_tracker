class Project 
  include Mongoid::Document
  validates_uniqueness_of :name
  referenced_in :coder
  referenced_in :org    
  references_many :commits 
  
  # given a github url, goto github and grab the project data
  #
  # @param repo_url The url of the repo, i.e. "https://githubcom/codeforamerica/fcc_reboot"
  # @return Project or Error
  # @example Project.new.get_details("https://github.com/codeforamerica/shortstack")
  
  def get_details(repo_url)  
    repo_name = parse_repo(repo_url)
    if repo_name[0] 
      begin
        repo = Octokit.repo(repo_name)
      rescue
        return false, "We had a problem finding that repository"
      else
        return Project.create!(repo)
      end
    else
      return false, repo_name
    end
  end

  # given a github url, parse the url and return a string
  #
  # @param repo_url The url of the repo, i.e. "https://githubcom/codeforamerica/fcc_reboot"
  # @return String or Error
  # @example Project.new.parse_repo("https://github.com/codeforamerica/shortstack")
  
  def parse_repo(url)
    begin
      domain = Domainatrix.parse(url)
    rescue 
      return false, "We had trouble parsing that url"
    else
      repo_name = domain.path.split("/")[1] + "/" + domain.path.split("/")[2]
    end
  end

  # grab the commits for a repository
  #
  # @param page and the branch
  # @return last commit or Error
  # @example Project.first.get_commits(1)
  def get_commits(page, branch = "master")
    repo_name = parse_repo(self.url)
    Octokit.commits(repo_name, "master", {:page => page})
    begin
      commits = Octokit.commits(repo_name, "master", {:page => page})
    rescue 
      return false, "No commits here!"
    else
      commits.each do |commit|
        coder = Coder.new.find_or_create(commit.author.login)    
        self.commits.create(:sha => commit.id, :branch => branch, :message => commit.message, :coder_id => coder.id, :committed_date => commit.committed_date)
      end
    end
  end
  
end