#!/bin/bash
ALB=$(terraform -chdir=terraform output -raw alb_dns)
echo "Testing ALB: http://$ALB/"
curl http://$ALB/
curl http://$ALB/health