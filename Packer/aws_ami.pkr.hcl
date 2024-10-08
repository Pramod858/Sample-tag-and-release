packer {
    required_plugins {
        amazon = {
        version = ">= 1.3.2"
        source  = "github.com/hashicorp/amazon"
        }
    }
}

variable "ami_prefix" {
    type    = string
    default = "packer-laravel-app"
}

locals {
    timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "laravel_ami" {
    ami_name             = "${var.ami_prefix}-${local.timestamp}"
    instance_type        = "t4g.micro"
    region               = "us-east-1"
    ssh_username         = "ubuntu"
    associate_public_ip_address = true

    source_ami_filter {
        filters = {
        name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"
        root-device-type    = "ebs"
        virtualization-type = "hvm"
        architecture        = "arm64"
        }
        owners      = ["099720109477"]
        most_recent = true
    }
}

build {
    name    = "packer-laravel-ami"
    sources = ["source.amazon-ebs.laravel_ami"]

    provisioner "shell" {
        environment_vars = [
        "DEBIAN_FRONTEND=noninteractive"
        ]

        inline = [
        "sudo add-apt-repository ppa:ondrej/php -y",
        "sudo apt update",
        "sudo apt upgrade -y",
        "sudo apt install -y php7.4 php7.4-cli php7.4-mbstring php7.4-xml php7.4-zip php7.4-curl php7.4-gd git unzip",
        "php -v",
        "curl -sS https://getcomposer.org/installer | sudo php",
        "sudo mv composer.phar /usr/local/bin/composer",
        "cd /home/ubuntu",
        "git clone https://github.com/niwasawa/php-laravel-hello-world.git",
        "cd php-laravel-hello-world",
        "composer install --no-scripts",
        "php artisan key:generate",
        "echo '[Unit]' | sudo tee /etc/systemd/system/laravel.service",
        "echo 'Description=Laravel Application' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo 'After=network.target' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo '[Service]' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo 'Type=simple' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo 'User=ubuntu' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo 'WorkingDirectory=/home/ubuntu/php-laravel-hello-world' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo 'ExecStart=/usr/bin/php artisan serve --host=0.0.0.0 --port=8000' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo 'Restart=on-failure' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo '[Install]' | sudo tee -a /etc/systemd/system/laravel.service",
        "echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/laravel.service",
        "sudo systemctl enable laravel.service",
        "sudo systemctl start laravel.service"
        ]
    }
}
