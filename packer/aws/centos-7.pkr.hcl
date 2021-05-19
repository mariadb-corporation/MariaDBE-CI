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
  default = "ami-0fb524dd81ac85f5d"
}

source "amazon-ebs" "centos-7" {
  profile = "jenkins-ci"
  ami_name = "centos-7-arm64"
  instance_type = "t4g.micro"
  region = "us-east-2"
  source_ami = "${var.ami_id}"
  ssh_username  = "centos"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = "60"
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.centos-7"]
  provisioner "shell" {
    inline = [
        "sleep 120",
        "sudo yum -y install wget tar gzip bzip2",
        "sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || true",
        "sudo yum -y upgrade", "sudo yum -y groupinstall 'Development Tools'", "sudo yum -y install unixODBC-devel unixODBC",
        "sudo yum -y install git python-devel libffi-devel openssl-devel gdb checkpolicy policycoreutils-python",
        "sudo yum -y install python-pip redhat-rpm-config curl bison libaio lsof perl-DBI boost-program-options ncurses-devel wget perl-XML-Simple",
        "sudo yum -y install perl-Time-HiRes perl-Test-HTTP-Server-Simple libcurl-devel mhash-devel sudo libxml2-devel libaio-devel scons",
        "sudo yum -y install boost-devel check-devel which Judy-devel cracklib-devel pam-devel rsync socat lsof valgrind redhat-lsb-core expect",
        "sudo yum -y install clang perl-CPAN jemalloc net-tools snappy-devel perl-DBI perl-DBD-MySQL readline-devel systemd-devel",
        "sudo yum -y install lz4-devel bzip2-devel libzstd-devel lzo-devel snappy-devel",
        "sudo rm /etc/security/limits.d/90-nproc.conf || true", "sudo yum -y erase cmake || true",
        "wget https://cmake.org/files/v3.19/cmake-3.19.8-Linux-aarch64.sh -O /tmp/cmake-3.19.8-Linux-aarch64.sh",
        "sudo /bin/bash /tmp/cmake-3.19.8-Linux-aarch64.sh --prefix=/usr --exclude-subdir --skip-license",
        "rm -f /tmp/cmake-3.19.8-Linux-aarch64.sh", "sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel libpmem-devel",
    ]
  }
}

