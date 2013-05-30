#!/bin/bash

echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
echo "SCRIPT-INIT Started at $(date)"
echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'

get_distrib() {
  distrib='not_supported'
  __lsb_release_cmd="$(type -p lsb_release 2> /dev/null)"
  if [ "x${__lsb_release_cmd}" != "x"] && [ -x "${__lsb_release_cmd}" ]
  then
    distrib="$(lsb_release -si)"
    echo $distrib | egrep '^Red.{0,1}Hat' > /dev/null 2>&1 && \
      distrib='rhel'
    [ "x$distrib" == "x" ] && distrib='not_supported'
    echo $distrib | tr '[:upper:]' '[:lower:]' | sed 's/ //g'
    return 0
  fi

  if [ -f /etc/redhat-release ]
  then
    distrib="$(cat /etc/redhat-release)"
    echo $distrib | egrep '^Red.{0,1}Hat' > /dev/null 2>&1 && distrib='rhel'
  elif [ -f /etc/lsb-release ]
  then
    source /etc/lsb-release
    distrib="$DISTRIB_ID"
    [ "x$distrib" == "x" ] && distrib='not_supported'
  else
    distrib='not_supported'
  fi
  echo $distrib|tr '[:upper:]' '[:lower:]' | sed 's/ //g'
}

# RVM

case "$(get_distrib)" in
  centos|rhel) 
    #TODO: Support only version 5.
    rpm -Uv http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm || true
    yum install -y --nogpgcheck bash curl git gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 iconv-devel
  ;;
  ubuntu|debian)
    apt-get update -y
    #TODO: Not tested on debian
    apt-get install libxslt1.1 libxslt-dev xvfb build-essential git-core curl -y
  ;;
  not_supported)
    exit 0
  ;;
esac

curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3
source /usr/local/rvm/scripts/rvm

# PUPPET
rvm ruby-1.9.3-p429@puppet --default --create
rvm wrapper ruby-1.9.3-p429@puppet puppet ruby
__gem_cmd='/usr/local/rvm/wrappers/ruby-1.9.3-p429@puppet/gem'
${__gem_cmd} install -y --no-rdoc --no-ri puppet -v '~> 2.7'

# SWAP
dd if=/dev/zero of=/.swap bs=1M count=1024 && \
mkswap /.swap && \
swapon /.swap
[ -f /.swap ] && echo '/.swap swap swap defaults 0 0' | tee -a /etc/fstab
echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
echo "SCRIPT-INIT Ended at $(date)"
echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
