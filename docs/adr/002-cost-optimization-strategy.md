# ADR 002: Cost Optimization Strategy

## Status
Accepted

## Context
Building a DevSecOps learning platform on AWS while keeping costs under $50/month.

## Decision
Implement a multi-pronged cost optimization strategy.

## Strategy Details

### 1. Single Environment
- One environment (dev) instead of dev/staging/prod
- Saves ~$500/month in infrastructure duplication

### 2. Auto-Shutdown Scheduler
- Lambda function scales down ECS to 0 tasks at 6 PM EST
- Lambda function stops RDS at 6 PM EST
- Lambda function scales up at 8 AM EST
- Expected savings: ~40% of compute costs

### 3. VPC Endpoints over NAT Gateway
- See ADR 001
- Saves ~$28/month

### 4. Free Tier Utilization
- RDS db.t3.micro (Free Tier eligible)
- Lambda (1M free requests/month)
- S3 (5GB free)
- CloudWatch (10 custom metrics free)

### 5. Minimal Monitoring
- 7-day log retention instead of 30 days
- 3 essential alarms only
- Container Insights disabled

### 6. Skip Optional Services (Initially)
- ElastiCache Redis: ~$15/month saved
- GuardDuty: ~$10/month saved
- Security Hub: ~$5/month saved
- WAF: ~$6/month saved

## Expected Monthly Cost

| Component | Cost |
|-----------|------|
| S3 + DynamoDB (state) | $0.50 |
| VPC Endpoints | $7.00 |
| KMS | $1.00 |
| RDS (Free Tier) | $0.00 |
| ALB | $16.00 |
| ECS Fargate (8hrs/day) | $5.00 |
| CloudWatch | $3.00 |
| **Total** | **~$32.50** |

## Consequences

### Positive
- Budget under $50/month achievable
- Still demonstrates enterprise patterns
- Can scale up for production

### Negative
- No multi-environment testing
- Limited monitoring capabilities
- Downtime during off-hours

### Future Considerations
- Add security services for portfolio demos (temporary)
- Upgrade to full monitoring for production
- Add multi-environment when needed
