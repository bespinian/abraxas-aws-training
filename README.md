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
accounts:
  <your-account-id>:
    filters:
      IAMUser:
        - "admin-user"  # optionally exclude some resources
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