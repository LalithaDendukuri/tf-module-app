#!/bin/bash
yum install ansible -y &>>/opt/userdata.log
ansible-pull -i localhost, -U https://github.com/LalithaDendukuri/roboshop-ansible_auto.git main.yml -e component=${component} &>>/opt/userdata.log