#!/bin/bash
while /bin/true; do
systemctl start httpd
systemctl start crond
sleep 60
done