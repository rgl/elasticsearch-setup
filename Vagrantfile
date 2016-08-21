Vagrant.configure(2) do |config|
  # you first need to build the base image with:
  # git clone https://github.com/joefitzgerald/packer-windows
  # cd packer-windows
  # # this will take ages so leave it running over night...
  # packer build windows_2012_r2.json
  # vagrant box add windows_2012_r2 windows_2012_r2_virtualbox.box
  # cd ..
  # then finally you vagrant up this vagrant environment. 
  config.vm.box = "windows_2012_r2"
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 4096
    vb.customize ["modifyvm", :id, "--vram", 64]
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end
  config.vm.provision "shell", inline: "$env:chocolateyVersion='0.10.0'; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex", name: "Install Chocolatey"
  config.vm.provision "shell", path: "Vagrantfile-locale.ps1"
  config.vm.provision "shell", path: "Vagrantfile-provision.ps1"
end