#! /bin/bash

sudo touch /home/ubuntu/.env
sudo echo 'HOST='${aws_db_host}'' >> //home/ubuntu/.env
sudo echo 'PORT='${aws_app_port}'' >> /home/ubuntu/.env
sudo echo 'DB_USER='${aws_db_username}'' >> /home/ubuntu/.env
sudo echo 'DB_PASSWORD='${aws_db_password}'' >> /home/ubuntu/.env
sudo echo 'DATABASE='${aws_db_name}'' >> /home/ubuntu/.env
sudo echo 'AWS_REGION='${aws_region}'' >> /home/ubuntu/.env
sudo echo 'AWS_BUCKET_NAME='${s3_bucket_name}'' >> /home/ubuntu/.env
sudo echo 'DOMAIN_NAME='${aws_domainName}'' >> /home/ubuntu/.env
sudo echo 'AWS_ENVIORMENT='${aws_environment}'' >> /home/ubuntu/.env
sudo echo 'AWS_TOPIC_ARN='${aws_topic_arn}'' >> /home/ubuntu/.env