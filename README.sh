# One-Click Deployment of Python REST API on AWS

## Deployment
```bash
./scripts/deploy.sh

Test
./scripts/test.sh

Teardown
./scripts/destroy.sh

✅ This setup ensures:  
- Private EC2 instances behind ALB and ASG  
- REST API running on port 8080  
- Logs in stdout  
- No public SSH, uses SSM  
- Repeatable Terraform deployment  
- One-click deploy/destroy  