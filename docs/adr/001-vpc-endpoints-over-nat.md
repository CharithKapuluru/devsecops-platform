# ADR 001: VPC Endpoints over NAT Gateway

## Status
Accepted

## Context
Private subnets in AWS VPC need a way to access AWS services (ECR, CloudWatch Logs, Secrets Manager). The two main options are:

1. **NAT Gateway**: Provides outbound internet access for private subnets
2. **VPC Endpoints**: Direct, private connectivity to AWS services

## Decision
Use VPC Endpoints instead of NAT Gateway.

## Rationale

### Cost
- NAT Gateway: ~$35/month (fixed) + data transfer charges
- VPC Endpoints: ~$7/month for interface endpoints + S3 gateway (free)
- **Savings: ~$28/month**

### Security
- VPC Endpoints keep traffic within AWS network
- No exposure to public internet
- Fine-grained security group control

### Required Endpoints
- S3 Gateway Endpoint (FREE)
- ECR API Interface Endpoint
- ECR DKR Interface Endpoint
- CloudWatch Logs Interface Endpoint
- Secrets Manager Interface Endpoint

### Trade-offs
- Cannot access external APIs from private subnets
- Each new AWS service requires a new endpoint
- For external API access, would need to add NAT Gateway or move to public subnet

## Consequences

### Positive
- Lower monthly costs
- Better security posture
- Simpler network architecture for AWS-only communication

### Negative
- Cannot call external APIs from ECS tasks
- Need to add endpoints for each new AWS service

### Mitigation
- If external API access is needed later, can add NAT Gateway
- Alternatively, use Lambda in public subnet for external calls
