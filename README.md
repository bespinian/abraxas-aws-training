# Clean-Up

## Install AWS Nuke

### macos

```bash
brew tap rebuy-de/rebuy
brew install aws-nuke
```

### ubuntu

```bash
sudo apt update
sudo apt install -y git curl unzip
sudo apt install -y golang
```

Test go:

```bash
go version
```

Download the repo:
```bash
git clone https://github.com/rebuy-de/aws-nuke.git
cd aws-nuke
make build
```

Move the binary to Your Path:
```bash
sudo mv aws-nuke /usr/local/bin/
```

Test the version
```bash
aws-nuke --version
```

Confirm 

## Use this config file
```yml
regions:
  - global
  - us-east-1
  - us-west-2
  - eu-west-1

account-blocklist:
  - "000000000000" # <-- Replace with your actual root account ID if you want to protect it

accounts:
  "nuke-target-account":
    filters:
      IAMUser:
        - "root"              # Do NOT try to delete the root user
      IAMRole:
        - "OrganizationAccountAccessRole" # Protect default org role
```

## Duke Nuke'em
1. Dry run first:
```bash
aws-nuke -c nuke-config.yaml --profile <your-profile> --account-id <your-account-id> --no-dry-run
```
2. Go for the real deal:
```bash
aws-nuke -c nuke-config.yaml --profile <your-profile> --account-id <your-account-id> 
```