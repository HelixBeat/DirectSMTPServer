# DirectSMTPServer (Minimal H1 Test)

## Description
This is a minimal Direct Secure SMTP Server for H1 testing. 
It supports TLS/STARTTLS, basic S/MIME verification, and Direct domain filtering.

## Setup
1. Ensure Java 17+ is installed
2. Ensure Maven is installed
3. Navigate to project root

## Run Server
```bash
mvn compile exec:java -Dexec.mainClass="com.directsmtp.DirectSMTPServer"
```

## Test TLS
```bash
openssl s_client -connect localhost:587 -starttls smtp
```

## Send Test Email
- Use Thunderbird or OpenSSL to send a signed S/MIME email to `@direct.if-else.com`

## Notes
- This server uses a self-signed certificate for local testing.
- Replace with real DirectTrust certificates for production.
- Place trust bundle certificates in `src/main/resources/trust_bundle/`
