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
  default = "ami-0bbc8e5afc278f8af"
}

source "amazon-ebs" "debian-10-buster" {
  profile = "jenkins-ci"
  ami_name = "debian-10-buster-arm64"
  instance_type = "t4g.micro"
  region = "us-east-2"
  source_ami = "${var.ami_id}"
  ssh_username  = "admin"
  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = "60"
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.debian-10-buster"]
  provisioner "shell" {
    inline = [
        "sleep 120",
        "sudo sed -i~orig -e 's/# deb-src/deb-src/' /etc/apt/sources.list", "sudo apt-get update",
        "sudo apt-get -y dist-upgrade", "sudo apt-get -y build-dep mariadb-server", "sudo apt-get -y install apt-utils build-essential",
        "sudo apt-get -y install python-dev sudo git devscripts equivs libcurl4-openssl-dev python3 python3-pip curl libssl-dev",
        "sudo apt-get -y install libzstd-dev libevent-dev dpatch gawk gdb libboost-dev libcrack2-dev libjudy-dev libnuma-dev",
        "sudo apt-get -y install libsnappy-dev libxml2-dev unixodbc-dev uuid-dev fakeroot iputils-ping unixodbc-dev unixodbc",
        "sudo apt-get -y install libmhash-dev libxml2-dev libxml-simple-perl gnutls-dev libaio-dev libpam-dev",
        "sudo apt-get -y install scons libboost-program-options-dev libboost-system-dev libboost-filesystem-dev check",
        "sudo apt-get -y install socat lsof sudo dh-systemd valgrind apt-transport-https dirmngr libdbi-perl libdbd-mysql-perl",
        "sudo apt-get -y install software-properties-common dirmngr rsync netcat libpcre2-dev default-jdk",
        "sudo apt-get -y install libboost-all-dev libsnappy-dev flex expect libjemalloc2 net-tools pkg-config libsystemd-dev",
        "sudo apt-get -y install libedit-dev liblz4-dev pkg-config liblz4-dev libbz2-dev libzstd-dev liblzo2-dev libsnappy-dev",
        "sudo apt-get -y -t buster-backports install libpmem-dev",
        "sudo sed -i 's|1|0|g' /etc/apt/apt.conf.d/20auto-upgrades"
    ]
  }
}

