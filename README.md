Builds kali vagrant box

[![Build and Publish Box](https://github.com/orrors/kali-vagrant/actions/workflows/build_and_publish.yml/badge.svg)](https://github.com/orrors/kali-vagrant/actions/workflows/build_and_publish.yml)

# Usage

```
make
```

Box versions are deployed automatically here when changes are made to master:

https://portal.cloud.hashicorp.com/vagrant/discover/0rr0rs/kali

### Refer to this to authenticate on hashicorp vagrant cloud

https://developer.hashicorp.com/vagrant/vagrant-cloud/hcp-vagrant/post-migration-guide

To init a box run

```bash
vagrant init 0rr0rs/kali
vagrant up
```

<details><summary><a href="./example/Vagrantfile">Or you can use the Vagrantfile in the examples directory</a></summary>

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

$provision = <<-SCRIPT
ln -s /vagrant ~/vagrant
sudo gunzip /usr/share/wordlists/rockyou.txt.gz
echo | sudo tee /etc/motd
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = '0rr0rs/kali'
  config.vm.define "orrors-kali"
  config.vm.hostname = 'orrors'

  config.vm.provider 'libvirt' do |libvirt|
    libvirt.cpus = 8
    libvirt.memory = 8192
    libvirt.memorybacking :access, :mode => "shared"

    libvirt.graphics_type  = "spice"
    libvirt.nic_model_type = "virtio"
    libvirt.sound_type     = "ich6"
    libvirt.video_type     = "qxl"

    libvirt.channel :type  => 'spicevmc', :target_name => 'com.redhat.spice.0',     :target_type => 'virtio'
    libvirt.channel :type  => 'unix',     :target_name => 'org.qemu.guest_agent.0', :target_type => 'virtio'
    libvirt.random  :model => 'random'
  end

  config.vm.synced_folder "./", "/vagrant", type: "virtiofs"

  # Forward X
  config.ssh.forward_agent = true
  config.ssh.forward_x11 = true

  # Open ports
  config.vm.network "forwarded_port", guest: 4444, host: 4444
  config.vm.network "forwarded_port", guest: 8000, host: 8000

  config.vm.provision "shell", inline: $provision, privileged: false
end
```

</details>

## Notes:

Run the script `./scripts/bump-kali-version.sh` to update files to use the newest kali version

