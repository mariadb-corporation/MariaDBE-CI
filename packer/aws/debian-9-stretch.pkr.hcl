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
  default = "ami-0d317a1f6804449b1"
}

source "amazon-ebs" "debian-9-stretch" {
  profile = "jenkins-ci"
  ami_name = "debian-9-stretch-arm64"
  instance_type = "t4g.micro"
  region = "us-east-2"
  source_ami = "${var.ami_id}"
  ssh_username  = "admin"
  launch_block_device_mappings {
    device_name = "xvda"
    volume_size = "60"
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.debian-9-stretch"]
  provisioner "shell" {
    inline = [
        "sleep 120",
        "sudo sed -i 's:main:main contrib non-free:g' /etc/apt/sources.list", "sed -e 's:^deb:deb-src:g' /etc/apt/sources.list > src.list",
        "sudo mv src.list /etc/apt/sources.list.d/", "sudo apt-get update", "sudo mkdir -p /usr/share/man/man1",
        "sudo apt-get -y dist-upgrade", "sudo apt-get -y -f install", "sudo apt-get install -y default-jdk unixodbc-dev unixodbc",
        "sudo apt-get -y build-dep -q mariadb-server", "sudo apt-get -y install apt-utils build-essential python-dev sudo git",
        "sudo apt-get -y install devscripts equivs libcurl4-openssl-dev python3 python3-pip curl libssl-dev libzstd-dev libpcre2-dev",
        "sudo apt-get -y install libevent-dev dpatch gawk gdb libboost-dev libcrack2-dev libjudy-dev libnuma-dev libsnappy-dev libxml2-dev",
        "sudo apt-get -y install unixodbc-dev uuid-dev fakeroot iputils-ping dh-systemd libkrb5-dev libsystemd-dev libmhash-dev libxml-simple-perl",
        "sudo apt-get -y install libaio-dev gnutls-dev libpam-dev scons libboost-program-options-dev libboost-system-dev libboost-filesystem-dev check",
        "sudo apt-get -y install socat lsof valgrind apt-transport-https software-properties-common dirmngr rsync netcat libdbi-perl libdbd-mysql-perl",
        "sudo apt-get -y install libboost-all-dev libsnappy-dev flex expect libjemalloc1 net-tools autoconf automake libtool libsystemd-dev",
        "sudo apt-get -y install libedit-dev liblz4-dev pkg-config liblz4-dev libbz2-dev libzstd-dev liblzo2-dev libsnappy-dev",
        "sudo sed -i 's|1|0|g' /etc/apt/apt.conf.d/20auto-upgrades",
    ]
  }
}

