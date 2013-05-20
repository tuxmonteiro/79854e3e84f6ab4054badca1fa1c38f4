#require "capify-ec2/capistrano"

my_aws_key = "" # ~/.ssh/xxxxx.pem
puppet_cmd = "source /usr/local/rvm/environments/ruby-1.9.3-p429@puppet && test -f /usr/local/rvm/gems/ruby-1.9.3-p429@puppet/bin/puppet && /usr/local/rvm/gems/ruby-1.9.3-p429@puppet/bin/puppet"
facter_cmd = "source /usr/local/rvm/environments/ruby-1.9.3-p429@puppet && test -f /usr/local/rvm/gems/ruby-1.9.3-p429@puppet/bin/facter && /usr/local/rvm/gems/ruby-1.9.3-p429@puppet/bin/facter"
gem_cmd = "/usr/local/rvm/wrappers/ruby-1.9.3-p429@puppet/gem"
ruby_cmd = "/usr/local/rvm/wrappers/ruby-1.9.3-p429@puppet/ruby"
server_release = "ubuntu"
ec2_user = server_release == "ubuntu" ? "ubuntu" : "root"
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "#{my_aws_key}")]

set :user, ec2_user
role :ec2_servers, "" 

namespace :myec2  do
  desc "Get local hostname"
  task :gethost, :roles => :ec2_servers do
    run "hostname" 
  end
  namespace :puppet do
    desc "Puppet install"
    task :install, :roles => :ec2_servers do
      rvm::install
      run "#{sudo :as => 'root'} su - -c 'rvm gemset create puppet'"
      run "#{sudo :as => 'root'} su - -c 'rvm wrapper 1.9.3@puppet puppet ruby'"
      run "#{sudo :as => 'root'} su - -c '#{gem_cmd} install -y --no-rdoc --no-ri puppet -v \"~> 2.7\"'"
      puppet::version
    end
    desc "Puppet version"
    task :version, :roles => :ec2_servers do
      run "#{sudo :as => 'root'} su - -c '#{puppet_cmd} help | tail -1'"
    end
    desc "Facter"
    task :facter, :roles => :ec2_servers do
      run "#{sudo :as => 'root'} su - -c '#{facter_cmd}'"
    end

  end
  namespace :rvm do
    desc "RVM install"
    task :install, :roles => :ec2_servers do
      case server_release
      when "redhat_5"
        run "#{sudo :as => 'root'} rpm -ivh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm"
        run "#{sudo :as => 'root'} yum install -y --nogpgcheck bash curl git gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 iconv-devel"
      when "ubuntu"
        run "#{sudo :as => 'root'} apt-get update -y"
        run "#{sudo :as => 'root'} apt-get install libxslt1.1 libxslt-dev xvfb build-essential git-core curl -y"
      end
      run "#{sudo :as => 'root'} su - -c 'curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3'"
    end
  end
end
