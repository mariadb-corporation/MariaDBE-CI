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
  default = "ami-03c0b2562530b1c37"
}

source "amazon-ebs" "rhel-8" {
  profile = "jenkins-ci"
  ami_name = "rhel-8-arm64"
  instance_type = "t4g.micro"
  region = "us-east-2"
  source_ami = "${var.ami_id}"
  ssh_username  = "ec2-user"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = "60"
    delete_on_termination = true
  }
}

# libpmem-devel is unavailable here, we need some workaround, i.e. separate custom repo
build {
  sources = ["source.amazon-ebs.rhel-8"]
  provisioner "shell" {
    inline = [
        "sleep 120",
        "sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y",
        "sudo dnf config-manager --set-enabled codeready-builder-for-rhel-8-rhui-rpms",
        "sudo yum -y install wget tar gzip bzip2",
        "sudo yum -y groupinstall 'Development Tools'", "sudo yum -y install unixODBC-devel unixODBC",
        "sudo yum -y install git python3-devel libffi-devel openssl-devel gdb checkpolicy",
        "sudo yum -y install python3-pip redhat-rpm-config curl bison libaio lsof perl-DBI boost-program-options ncurses-devel wget perl-XML-Simple",
        "sudo yum -y install perl-Time-HiRes libcurl-devel mhash-devel sudo libxml2-devel libaio-devel python3-scons readline-devel systemd-devel",
        "sudo yum -y install boost-devel check-devel which Judy cracklib-devel pam-devel rsync socat lsof valgrind redhat-lsb-core expect",
        "sudo yum -y install clang perl-CPAN jemalloc net-tools snappy-devel perl-Memoize perl-DBI perl-DBD-MySQL",
        "sudo yum -y install lz4-devel bzip2-devel libzstd-devel lzo-devel snappy-devel",
        "sudo rm /etc/security/limits.d/90-nproc.conf || true", "sudo yum -y erase cmake || true",
        "wget https://cmake.org/files/v3.19/cmake-3.19.8-Linux-aarch64.sh -O /tmp/cmake-3.19.8-Linux-aarch64.sh",
        "sudo /bin/bash /tmp/cmake-3.19.8-Linux-aarch64.sh --prefix=/usr --exclude-subdir --skip-license",
        "rm -f /tmp/cmake-3.19.8-Linux-aarch64.sh", "sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel",
        "sudo rm -fv /etc/systemd/system/timers.target.wants/dnf-automatic.timer"
    ]
  }
}

