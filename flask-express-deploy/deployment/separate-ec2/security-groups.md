# Security Group Rules — Separate EC2s

## Backend EC2 (Flask)

| Type   | Protocol | Port | Source                    | Purpose                        |
|--------|----------|------|---------------------------|--------------------------------|
| SSH    | TCP      | 22   | Your IP                   | SSH access                     |
| Custom | TCP      | 5000 | Frontend EC2 Security Group | Allow frontend to reach Flask |

## Frontend EC2 (Express)

| Type  | Protocol | Port | Source    | Purpose             |
|-------|----------|------|-----------|---------------------|
| SSH   | TCP      | 22   | Your IP   | SSH access          |
| HTTP  | TCP      | 80   | 0.0.0.0/0 | Public web access   |
| HTTPS | TCP      | 443  | 0.0.0.0/0 | Optional SSL        |

> Tip: Reference the backend's security group ID as the source for port 5000
> instead of using a public IP — this is more secure.
