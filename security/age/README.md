# age + SOPS Secrets

This folder documents how to bootstrap age keys for encrypting your `.env` file with [SOPS](https://github.com/mozilla/sops).

1. Generate a key pair:
   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```
2. Copy the public key (line starting with `age1...`) into `security/sops/example.env.sops` to define the recipients.
3. Encrypt your `.env`:
   ```bash
   sops --encrypt --age "$(grep '^# public key' -A1 ~/.config/sops/age/keys.txt | tail -n1)" .env > .env.sops
   ```
4. Decrypt on the EdgeBox host during deployment:
   ```bash
   sops --decrypt .env.sops > .env
   ```

Keep the private key secure; anyone with access can decrypt your secrets.
