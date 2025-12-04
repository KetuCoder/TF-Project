#!/bin/bash
ALB_DNS=$(terraform -chdir=terraform output -raw alb_dns)
echo "Testing ALB: http://$ALB_DNS/"
curl http://$ALB_DNS/
curl http://$ALB_DNS/health