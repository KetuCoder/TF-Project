#!/bin/bash
ALB_URL=$(terraform -chdir=terraform output -raw alb_url)
curl http://$ALB_URL
curl http://$ALB_URL/health