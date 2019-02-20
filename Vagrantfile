# you must install this plugin to set the disk size:
# vagrant plugin install vagrant-disksize

Vagrant.configure("2") do |config|
  # Ubuntu 16.04
  config.vm.box = "ubuntu/xenial64"
  config.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
  config.disksize.size = '50GB'
  config.vm.network "public_network", bridge: "eno1"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
    # Customize the amount of memory on the VM:
    vb.memory = "8192"
    vb.cpus = 4
    vb.customize ["modifyvm", :id, "--accelerate2dvideo", "on"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']  
  end
  # Install ubuntu desktop and virtualbox additions
  config.vm.provision "shell", inline: "sudo apt-get update"
  config.vm.provision "shell", inline: "sudo apt-get install -y ubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 xserver-xorg-legacy"
  # Permit anyone to start the GUI
  config.vm.provision "shell", inline: "sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config"
  #disable the update notifier.  We do not want to update to ubuntu 18, currently deadline installer gui doesn't work in 18.
  config.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  # install ansible
  config.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
  config.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  config.vm.provision "shell", inline: "sudo apt-get install -y ansible"
  #reboot required for desktop to function.
  config.vm.provision "shell", inline: "sudo reboot"
  # trigger reload
  config.vm.provision :reload
  #ansible provissioning
  #ansible_inventory_dir = "ansible/hosts"
  #config.vm.provision "playbook1", type:'ansible' do |ansible|
    #ansible.playbook = "ansible/install-terraform.yaml"
    #ansible.playbook = "playbook.yaml"
    #ansible.inventory_path = "#{ansible_inventory_dir}/vagrant"
    #ansible.inventory_path = "./ansible/hosts"
  #end
end