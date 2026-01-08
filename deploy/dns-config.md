# DNS Configuration for DirectSMTP Server

## Required DNS Records

### 1. A Record
```
direct.if-else.com    A    YOUR_SERVER_IP
```

### 2. MX Record (Mail Exchange)
```
if-else.com    MX    10    direct.if-else.com
```

### 3. SPF Record (Sender Policy Framework)
```
if-else.com    TXT    "v=spf1 ip4:YOUR_SERVER_IP ~all"
```

### 4. DKIM Record (Optional but recommended)
```
default._domainkey.if-else.com    TXT    "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"
```

### 5. DMARC Record (Optional but recommended)
```
_dmarc.if-else.com    TXT    "v=DMARC1; p=quarantine; rua=mailto:dmarc@if-else.com"
```

## DNS Provider Examples

### Cloudflare
1. Login to Cloudflare dashboard
2. Select your domain
3. Go to DNS settings
4. Add the records above

### Route 53 (AWS)
```bash
# Create hosted zone
aws route53 create-hosted-zone --name if-else.com --caller-reference $(date +%s)

# Add A record
aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch '{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "direct.if-else.com",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "YOUR_SERVER_IP"}]
    }
  }]
}'
```

### Google Cloud DNS
```bash
# Create DNS zone
gcloud dns managed-zones create if-else-com --dns-name=if-else.com --description="DirectSMTP Zone"

# Add A record
gcloud dns record-sets transaction start --zone=if-else-com
gcloud dns record-sets transaction add YOUR_SERVER_IP --name=direct.if-else.com --ttl=300 --type=A --zone=if-else-com
gcloud dns record-sets transaction execute --zone=if-else-com
```

## Testing DNS Configuration

```bash
# Test A record
dig direct.if-else.com A

# Test MX record
dig if-else.com MX

# Test SPF record
dig if-else.com TXT
```