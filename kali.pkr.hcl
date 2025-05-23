packer {
  required_plugins {
    qemu = {
      version = "1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "version" {
  type = string
}

variable "vagrant_box" {
  type = string
}

variable "description" {
  type = string
}

variable "hcp_client_id" {
  type    = string
  default = "${env("HCP_CLIENT_ID")}"
}

variable "hcp_client_secret" {
  type    = string
  default = "${env("HCP_CLIENT_SECRET")}"
}

source "qemu" "kali-amd64" {
  accelerator      = "kvm"
  machine_type     = "q35"
  efi_boot         = true
  cpus             = 4
  memory           = 4 * 1024
  qemuargs         = [["-cpu", "host"]]
  headless         = true
  net_device       = "virtio-net"
  http_directory   = "."
  format           = "qcow2"
  disk_size        = 40 * 1024
  disk_interface   = "virtio-scsi"
  disk_cache       = "unsafe"
  disk_discard     = "unmap"
  disk_compression = true
  iso_url          = "https://cdimage.kali.org/current/kali-linux-${var.version}-installer-netinst-amd64.iso"
  iso_checksum     = "file:http://kali.download/base-images/kali-${var.version}/SHA256SUMS"
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  boot_wait        = "5s"
  boot_command     = [
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.cfg",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter><wait>",
    "initrd /install.amd/initrd.gz",
    "<enter><wait>",
    "boot",
    "<enter><wait>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
}

build {
  sources = [ "source.qemu.kali-amd64" ]

  provisioner "shell" {
    expect_disconnect = true
    execute_command   = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision/00-custom_software.sh",
      "provision/01-xfce.sh",
      "provision/97-guest-additions.sh",
      "provision/98-vagrant.sh",
      "provision/99-cleanup.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      only                 = [ "qemu.kali-amd64" ]
      output               = var.vagrant_box
      vagrantfile_template = "Vagrantfile.template"
    }

    post-processor "vagrant-registry" {
      box_tag             = "0rr0rs/kali"
      version             = "${var.version}"
      client_id           = "${var.hcp_client_id}"
      client_secret       = "${var.hcp_client_secret}"
      architecture        = "amd64"
      version_description = "${var.description}"
    }
  }
}
