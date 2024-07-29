packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
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

variable "disk_size" {
  type    = string
  default = 40 * 1024
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.kali.org/kali-2024.2/kali-linux-2024.2-installer-netinst-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:cd6f784b4e999daa50ab53950669920e0d6b7902be0945314ac234a0f5ee3344"
}

source "qemu" "kali-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  efi_boot     = true
  cpus         = 4
  memory       = 4 * 1024
  qemuargs = [
    ["-cpu", "host"],
  ]
  # headless       = true
  net_device     = "virtio-net"
  http_directory = "."
  format         = "qcow2"
  disk_size      = var.disk_size
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  iso_url        = var.iso_url
  iso_checksum   = var.iso_checksum
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "60m"
  boot_wait      = "10s"
  boot_command = [
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter><wait5s>",
    "initrd /install.amd/initrd.gz",
    "<enter><wait5s>",
    "boot",
    "<enter><wait5s>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
}

build {
  sources = [
    "source.qemu.kali-amd64",
  ]

  provisioner "shell" {
    expect_disconnect = true
    execute_command   = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision-guest-additions.sh",
      "provision.sh"
    ]
  }

  post-processor "vagrant" {
    only = [
      "qemu.kali-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
