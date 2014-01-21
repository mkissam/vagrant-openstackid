# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise64"
  config.vm.host_name = "openid-dev"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.network :private_network, ip: "192.168.27.152"
  config.vm.provider :virtualbox do |vb|
     vb.customize ["modifyvm", :id, "--memory", "2048"]
  end
  config.vm.provision :shell, :path => "scripts/bootstrap.sh"
end
