#!/bin/bash
yum update -y
amazon-linux-extras enable postgresql14
yum install -y postgresql-server postgresql-contrib
postgresql-setup initdb
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'TechCorp123!';"