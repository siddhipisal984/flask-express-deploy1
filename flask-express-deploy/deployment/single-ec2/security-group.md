# Security Group Rules — Single EC2

| Type  | Protocol | Port | Source    | Purpose              |
|-------|----------|------|-----------|----------------------|
| SSH   | TCP      | 22   | Your IP   | SSH access           |
| HTTP  | TCP      | 80   | 0.0.0.0/0 | Nginx reverse proxy  |
| HTTPS | TCP      | 443  | 0.0.0.0/0 | (optional, with SSL) |
