# you must install this plugin to set the disk size:
# vagrant plugin install vagrant-disksize

Vagrant.configure("2") do |config|
  # Ubuntu 16.04
  config.vm.box = "ubuntu/xenial64"
  #config.vm.box = "bento/ubuntu-16.04"
  #config.ssh.username = "vagrant"
  #config.ssh.password = "vagrant"
  stage = ENV['TF_VAR_stage']
  if stage == 'prod'
    mac_string = ENV['TF_VAR_vagrant_mac_prod']
  end
  if stage == 'dev'
      mac_string = ENV['TF_VAR_vagrant_mac_dev']
  end

  config.vm.define "ansible_control"
  config.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
  config.disksize.size = '50GB'
  #config.vm.network "public_network", bridge: "eno1",
  config.vm.network "public_network", mac: mac_string
  
  # routing issues?  https://stackoverflow.com/questions/35208188/how-can-i-define-network-settings-with-vagrant
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
  # set mac
  
  # update packages
  config.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/Australia/Brisbane /etc/localtime", run: "always"
  config.vm.provision "shell", inline: "sudo apt-get update"
  config.vm.provision "shell", inline: "sudo apt-get install -y sshpass"
  # Install ubuntu desktop and virtualbox additions.  Because a reboot is required only two choices to provision-
  # Install the gui with vagrant or install the gui with ansible installed on the host.  
  # This creates potentiall issues because ideally, Ansible should be used within the vm only to limit ansible version issues if the user updates vagrant on their host.
  config.vm.provision "shell", inline: "sudo apt-get install -y ubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 xserver-xorg-legacy"
  # Permit anyone to start the GUI
  config.vm.provision "shell", inline: "sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config"
  #disable the update notifier.  We do not want to update to ubuntu 18, currently deadline installer gui doesn't work in 18.
  config.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  # install ansible
  config.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
  config.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  config.vm.provision "shell", inline: "sudo apt-get install -y ansible"
  # we define the location of the ansible hosts file in an environment variable.
  config.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
  #reboot required for desktop to function.
  config.vm.provision "shell", inline: "sudo reboot"
  # trigger reload
  config.vm.provision :reload
  #ansible provissioning
  #ansible_inventory_dir = "ansible/hosts"
  # config.vm.provision "playbook1", type:'ansible_local' do |ansible|
  #   ansible.playbook = "ansible/init.yaml"
  # end
  # vm.trigger.after :up do |trigger|
  #   trigger.warn = "Taking Snapshot"
  #   trigger.run = {inline: "vagrant snapshot push"}
  # end
  # first step before launching vagrant is to ensure an environment var is set with a random mac (you must generate it yourself)
  # export TF_VAR_vagrant_mac=000D391G7C51
  # if you are on a mac, install homebrew and ensure you have the command envsubst
  # brew install gettext
  # brew link --force gettext
  # get your router to assign/reserve a static ip using this same mac address.
  # run vagrant up.
  # upon completion, we are ready to provision playbook 
  # vagrant ssh
  # check that the right ip you wanted assigned is used with 'ip a'
  # cd /vagrant
  # now we will setup our environment variables from a template.
  # if you have already done this before, you will probably wan't to keep your old secrets.txt instead of copying in the template.
  # cp secrets.template secrets/secrets.txt
  # edit secrets/secrets.txt with your own unique values.  also copy in the mac address you set, eg TF_VAR_vagrant_mac=000D391G7C51
  # now we need to generate a random key for your vault.  if a key is present already in keys/.vault-key then it will be kept.
  # init-keys.yaml will also ecrypt secrets.txt if it is unencrypted with this new key.
  # ansible-playbook ansible/init-keys.yaml
  # ensure you have a backup of the key (keys/.vault-key).  Storing it on an encrypted usb key is a good idea!
  # now we can initialise our environment variables.
  # source ./update_vars.sh
  # ansible-playbook -i ansible/inventory/hosts ansible/init.yaml
  # download the deadline linux installers version 10.0.23.4 into downloads/Deadline-10.0.23.4-linux-installers.tar
  # ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml
  # remember to always run source ./update_vars.sh before running any ansible playbooks, or using terraform.
  # init your aws access key.
  # ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml
  # subscribe to these amis (it may take some time before your subscription is processed)-
  # openvpn https://aws.amazon.com/marketplace/pp/B00MI40CAE
  # centos7 https://aws.amazon.com/marketplace/pp/B00O7WM7QW?qid=1552746240289&sr=0-1&ref_=srh_res_product_title
  # softnas cloud platinum https://aws.amazon.com/marketplace/pp/B07DGMG5ZD?qid=1552746298127&sr=0-2&ref_=srh_res_product_title
  # softnas cloud platinum - lower compute https://aws.amazon.com/marketplace/pp/B07DGGZBCG?qid=1552746484959&sr=0-9&ref_=srh_res_product_title

  # now lets run out first terraform apply.
  # terraform apply
end