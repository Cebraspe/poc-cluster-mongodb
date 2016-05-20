# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessie64"

  config.vm.provision "file", source: "./poc_cluster", destination: "~/poc_cluster"
  config.vm.provision "shell", path: "./poc_cluster/install/mongodb_install.sh"
  config.vm.provision "shell", path: "./poc_cluster/install/nodejs_install.sh"
end
