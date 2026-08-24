# Cloud Custodian

## Getting Started

```
python3 -m venv custodian
source custodian/bin/activate
pip install c7n       # This includes AWS support
```

## Run the policies

```
AWS_PROFILE=pipeline custodian run --output-dir=./reports eks-policy.yaml --region all
```