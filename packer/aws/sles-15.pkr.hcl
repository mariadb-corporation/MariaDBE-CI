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
  default = "ami-0599e0cce3221db46"
}

source "amazon-ebs" "sles-15" {
  profile = "jenkins-ci"
  ami_name = "sles-15-arm64"
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
  sources = ["source.amazon-ebs.sles-15"]
  provisioner "shell" {
    inline = [
          "sleep 120",
          "until sudo SUSEConnect -p PackageHub/15.2/aarch64; do sleep 1; done",
          "until sudo zypper -n update --auto-agree-with-licenses; do sleep 5; done",
          "sudo zypper -n install gcc-c++ cmake libaio-devel pam-devel wget gdb",
          "sudo zypper -n install libgnutls-devel bison openssl-devel lsb-release",
          "sudo zypper -n install ncurses-devel libxml2-devel libcurl-devel systemd-devel",
          "sudo zypper -n install rsync socat lsof tar gzip bzip2 rpm-build libtool",
          "sudo zypper -n install checkpolicy policycoreutils curl perl perl-DBI perl-DBD-mysql",
          "sudo zypper -n install valgrind-devel sudo git scons perl-XML-Simple krb5-devel",
          "sudo zypper -n install libboost_program_options-devel systemd-devel cracklib-devel",
          "sudo zypper -n install libboost_filesystem-devel libboost_system-devel check-devel unixODBC unixODBC-devel",
          "sudo zypper -n install expect jemalloc net-tools flex libboost_*-devel autoconf automake libtool",
          "sudo zypper -n install snappy-devel liblz4-devel libzstd-devel libbz2-devel lzo-devel",
          "sudo zypper -n rm cmake || true",
          "wget https://cmake.org/files/v3.19/cmake-3.19.8-Linux-aarch64.sh -O /tmp/cmake-3.19.8-Linux-aarch64.sh",
          "sudo /bin/bash /tmp/cmake-3.19.8-Linux-aarch64.sh --prefix=/usr --exclude-subdir --skip-license",
          "rm -f /tmp/cmake-3.19.8-Linux-aarch64.sh",
          "sudo zypper -n install java-1_8_0-openjdk java-1_8_0-openjdk-devel libsepol1"
    ]
  }
}

