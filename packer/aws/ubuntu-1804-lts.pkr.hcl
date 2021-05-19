packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_id" {
  type    = string
  default = "ami-075205243a5e1cb0d"
}

source "amazon-ebs" "ubuntu-1804-lts" {
  profile = "jenkins-ci"
  ami_name = "ubuntu-1804-lts-arm64"
  instance_type = "t4g.micro"
  region = "us-east-2"
  source_ami = "${var.ami_id}"
  ssh_username  = "ubuntu"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = "60"
    delete_on_termination = true
  }
}

# libpmem-dev is unavailable on
build {
  sources = ["source.amazon-ebs.ubuntu-1804-lts"]
  provisioner "shell" {
    inline = [
              "sleep 120",
              "sudo sed -i~orig -e 's/# deb-src/deb-src/' /etc/apt/sources.list", "sudo apt-get update",
              "sudo mkdir -p /usr/share/man/man1",
              "sudo apt-get -y dist-upgrade", "sudo apt-get -y -f install", "sudo apt-get install -y default-jdk unixodbc-dev unixodbc",
              "sudo cat /etc/apt/sources.list",
              "sudo apt-get -y build-dep mariadb-server", "sudo apt-get -y install apt-utils build-essential python-dev sudo git",
              "sudo apt-get -y install devscripts equivs libcurl4-openssl-dev python3 python3-pip curl libssl-dev libzstd-dev dh-exec",
              "sudo apt-get -y install libevent-dev dpatch gawk gdb libboost-dev libcrack2-dev libjudy-dev libnuma-dev libsnappy-dev libxml2-dev",
              "sudo apt-get -y install unixodbc-dev uuid-dev fakeroot iputils-ping dh-systemd libkrb5-dev libsystemd-dev libmhash-dev libxml-simple-perl",
              "sudo apt-get -y install libaio-dev gnutls-dev libpam-dev scons libboost-program-options-dev libboost-system-dev libboost-filesystem-dev check",
              "sudo apt-get -y install socat lsof valgrind apt-transport-https software-properties-common dirmngr rsync netcat libpcre2-dev libsystemd-dev",
              "sudo apt-get -y install libboost-all-dev libsnappy-dev flex expect libjemalloc1 net-tools autoconf automake libtool libdbi-perl libdbd-mysql-perl",
              "sudo apt-get -y install liblz4-dev libbz2-dev libzstd-dev liblzo2-dev libsnappy-dev",
              "sudo apt-get -y -t bionic-backports install debhelper",
              "sudo apt-get -y install libedit-dev liblz4-dev pkg-config",
              "sudo sed -i 's|1|0|g' /etc/apt/apt.conf.d/20auto-upgrades"
    ]
  }
}

