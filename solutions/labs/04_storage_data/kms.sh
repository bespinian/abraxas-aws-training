# Replace with your key alias or key ID
KEY_ID=$(aws kms list-aliases --query "Aliases[?AliasName=='alias/training-key-demo'].TargetKeyId" --output text)

# Encrypt a string
echo "SuperSecretValue123!" | \
  aws kms encrypt \
    --key-id "$KEY_ID" \
    --plaintext fileb:///dev/stdin \
    --output text \
    --query CiphertextBlob > secret.enc

# Decrypt the string
aws kms decrypt \
  --ciphertext-blob fileb://secret.enc \
  --output text \
  --query Plaintext | base64 --decode