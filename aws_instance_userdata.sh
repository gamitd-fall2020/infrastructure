#! /bin/bash
sudo mkdir /home/ubuntu/webapp
sudo chmod 777 /home/ubuntu/webapp
sudo touch /home/ubuntu/webapp/.env
sudo chmod 777 /home/ubuntu/webapp/.env
sudo echo 'HOST='${aws_db_host}'' >> /home/ubuntu/webapp/.env
sudo echo 'PORT='${aws_app_port}'' >> /home/ubuntu/webapp/.env
sudo echo 'DB_USER='${aws_db_username}'' >> /home/ubuntu/webapp/.env
sudo echo 'DB_PASSWORD='${aws_db_password}'' >> /home/ubuntu/webapp/.env
sudo echo 'DATABASE='${aws_db_name}'' >> /home/ubuntu/webapp/.env
sudo echo 'AWS_REGION='${aws_region}'' >> /home/ubuntu/webapp/.env
sudo echo 'AWS_BUCKET_NAME='${s3_bucket_name}'' >> /home/ubuntu/webapp/.env