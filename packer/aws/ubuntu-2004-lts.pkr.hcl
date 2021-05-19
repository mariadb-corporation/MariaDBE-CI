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
  default = "ami-0a067ba5e031abd5f"
}

source "amazon-ebs" "ubuntu-2004-lts" {
  profile = "jenkins-ci"
  ami_name = "ubuntu-2004-lts-arm64"
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

# libpmem-dev is unavailable on aws
build {
  sources = ["source.amazon-ebs.ubuntu-2004-lts"]
  provisioner "shell" {
    inline = [
              "sleep 120",
              "sudo sed -i~orig -e 's/# deb-src/deb-src/' /etc/apt/sources.list", "sudo apt-get update", "sudo mkdir -p /usr/share/man/man1",
              "sudo apt-get -y dist-upgrade", "sudo apt-get -y -f install", "sudo apt-get install -y default-jdk",
              "sudo apt-get -y install apt-utils build-essential python3-dev sudo git unixodbc-dev unixodbc",
              "sudo apt-get -y install devscripts equivs libcurl4-openssl-dev python3 python3-pip curl libssl-dev libzstd-dev dh-exec",
              "sudo apt-get -y install libevent-dev dpatch gawk gdb libboost-dev libcrack2-dev libjudy-dev libnuma-dev libsnappy-dev libxml2-dev",
              "sudo apt-get -y install unixodbc-dev uuid-dev fakeroot iputils-ping dh-systemd libkrb5-dev libsystemd-dev libmhash-dev libxml-simple-perl",
              "sudo apt-get -y install libaio-dev gnutls-dev libpam-dev scons libboost-program-options-dev libboost-system-dev libboost-filesystem-dev check",
              "sudo apt-get -y install socat lsof valgrind apt-transport-https software-properties-common dirmngr rsync netcat libpcre2-dev libsystemd-dev",
              "sudo apt-get -y install libboost-all-dev libsnappy-dev flex expect libjemalloc2 net-tools autoconf automake libtool libdbi-perl libdbd-mysql-perl",
              "sudo apt-get -y install chrpath debhelper bison cmake dh-apparmor libjemalloc-dev libncurses5-dev libpcre3-dev libreadline-gplv2-dev psmisc",
              "sudo apt-get -y install libedit-dev liblz4-dev pkg-config libarchive-dev libpmem-dev liblz4-dev libbz2-dev libzstd-dev liblzo2-dev libsnappy-dev",
              "sudo sed -i 's|1|0|g' /etc/apt/apt.conf.d/20auto-upgrades"
    ]
  }
}

