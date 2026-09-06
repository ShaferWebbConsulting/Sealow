# SeaLow iOS CI/CD Environment Variables and Secrets

This document explains the environment variables and GitHub Actions secrets used by the SeaLow iOS build, signing, App Store Connect upload, and TestFlight pipeline.

## Overview

The pipeline uses two types of configuration:

1. **Normal environment variables**
   - Safe identifiers such as the Apple Team ID, bundle ID, scheme name, and GitHub run number.
2. **GitHub Actions secrets**
   - Sensitive signing certificates, provisioning profiles, App Store Connect API credentials, and passwords.

Never commit signing certificates, private keys, provisioning profiles, `.p8` files, `.p12` files, or generated Base64 secret files into Git.

---

# GitHub Actions Secrets

Create these under:

**GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**

The required secrets are:

| Secret | Purpose |
|---|---|
| `APP_STORE_CONNECT_ISSUER_ID` | Identifies your App Store Connect API issuer |
| `APP_STORE_CONNECT_KEY_ID` | Identifies the App Store Connect API key |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Contents of the App Store Connect `.p8` private key |
| `IOS_CERTIFICATE_BASE64` | Base64-encoded Apple Distribution `.p12` signing certificate |
| `IOS_CERTIFICATE_PASSWORD` | Password protecting the `.p12` file |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded App Store Connect provisioning profile |

---

## `APP_STORE_CONNECT_ISSUER_ID`

### What it is

The Issuer ID identifies the App Store Connect API issuer associated with your Apple Developer / App Store Connect organization.

It is used with:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

to authenticate automated uploads to App Store Connect and TestFlight.

### Where to find it

Open:

**App Store Connect → Users and Access → Integrations → App Store Connect API**

You should see an **Issuer ID** near the API key section.

It normally looks like a UUID:

```text
12345678-1234-1234-1234-123456789abc
```

### GitHub secret

Create:

```text
APP_STORE_CONNECT_ISSUER_ID
```

Paste the Issuer ID exactly as shown in App Store Connect.

Do not Base64-encode it.

---

## `APP_STORE_CONNECT_KEY_ID`

### What it is

The Key ID identifies the App Store Connect API key used by the GitHub Actions pipeline.

### How to create it

Open:

**App Store Connect → Users and Access → Integrations → App Store Connect API**

Create a new API key with a role that is allowed to upload application builds.

When the key is created, Apple displays a **Key ID**.

Example:

```text
ABC123DEFG
```

### GitHub secret

Create:

```text
APP_STORE_CONNECT_KEY_ID
```

Paste the Key ID exactly as displayed.

Do not Base64-encode it.

---

## `APP_STORE_CONNECT_PRIVATE_KEY`

### What it is

This is the private `.p8` authentication key downloaded when you create an App Store Connect API key.

Apple typically names the file:

```text
AuthKey_ABC123DEFG.p8
```

The file looks similar to:

```text
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----
```

### Important

Apple only allows the private key file to be downloaded once.

Store it somewhere secure.

### GitHub secret

Create:

```text
APP_STORE_CONNECT_PRIVATE_KEY
```

Paste the **entire contents** of the `.p8` file, including:

```text
-----BEGIN PRIVATE KEY-----
```

and:

```text
-----END PRIVATE KEY-----
```

### Linux / Bash / Zsh

View the file:

```bash
cat AuthKey_ABC123DEFG.p8
```

Copy the entire output into the GitHub secret.

Do not Base64-encode this secret unless the workflow is specifically changed to expect Base64.

---

# Apple Distribution Signing Certificate

## `IOS_CERTIFICATE_BASE64`

### What it is

This secret contains a Base64-encoded Apple Distribution certificate package in PKCS#12 (`.p12`) format.

The `.p12` file must contain:

- the Apple Distribution certificate
- the matching private key

Both are required for code signing.

---

## Step 1: Create a private key

On Linux:

```bash
openssl genrsa \
  -out sealow_distribution.key \
  2048
```

Keep this file private.

Do not commit it.

---

## Step 2: Create a Certificate Signing Request

```bash
openssl req \
  -new \
  -key sealow_distribution.key \
  -out sealow_distribution.csr
```

You can enter your organization details when prompted.

---

## Step 3: Create the Apple Distribution certificate

Open:

**Apple Developer → Certificates, Identifiers & Profiles → Certificates**

Click:

```text
+
```

Choose:

```text
Apple Distribution
```

Upload:

```text
sealow_distribution.csr
```

Apple will generate a certificate.

Download it.

It will normally be named something similar to:

```text
distribution.cer
```

---

## Step 4: Convert the Apple `.cer` file to PEM

Apple normally provides the certificate in DER format.

Convert it:

```bash
openssl x509 \
  -inform DER \
  -in distribution.cer \
  -out distribution.pem
```

---

## Step 5: Create a macOS-compatible `.p12`

For GitHub Actions macOS runners, use a PKCS#12 format that macOS Keychain can reliably import.

Run:

```bash
openssl pkcs12 \
  -export \
  -inkey sealow_distribution.key \
  -in distribution.pem \
  -out sealow_distribution_macos.p12 \
  -name "SeaLow Apple Distribution" \
  -keypbe PBE-SHA1-3DES \
  -certpbe PBE-SHA1-3DES \
  -macalg sha1
```

You will be asked to create an export password.

That password becomes:

```text
IOS_CERTIFICATE_PASSWORD
```

---

## Step 6: Verify the `.p12`

```bash
openssl pkcs12 \
  -in sealow_distribution_macos.p12 \
  -info \
  -noout
```

Enter the password you created.

The command should succeed.

---

## Step 7: Base64-encode the `.p12`

Use OpenSSL with `-A` so the output stays on one line:

```bash
openssl base64 \
  -A \
  -in sealow_distribution_macos.p12 \
  -out certificate_base64.txt
```

You can validate it:

```bash
python3 - <<'PY'
from pathlib import Path
import base64

s = Path("certificate_base64.txt").read_text()

print("Length:", len(s))
print("Modulo 4:", len(s) % 4)
print("Newlines:", s.count("\n"))
print("Carriage returns:", s.count("\r"))

base64.b64decode(s, validate=True)

print("Base64 validation: PASS")
PY
```

Expected:

```text
Modulo 4: 0
Newlines: 0
Carriage returns: 0
Base64 validation: PASS
```

### Important Base64 note

The `/` character is valid Base64.

GitHub's web UI may visually wrap a long Base64 value near `/` characters. Visual wrapping does not necessarily mean the stored secret contains actual newlines.

The CI workflow also strips whitespace before decoding.

---

## Step 8: Create the GitHub secret

Create:

```text
IOS_CERTIFICATE_BASE64
```

Paste the contents of:

```text
certificate_base64.txt
```

Do not paste the path to the file.

Do not paste the binary `.p12` itself.

Do not paste the `.cer` file.

---

## `IOS_CERTIFICATE_PASSWORD`

### What it is

This is the password used when creating:

```text
sealow_distribution_macos.p12
```

### GitHub secret

Create:

```text
IOS_CERTIFICATE_PASSWORD
```

Paste the password exactly as entered when the `.p12` file was created.

Do not Base64-encode the password.

---

# Provisioning Profile

## `IOS_PROVISIONING_PROFILE_BASE64`

### What it is

This is the Base64-encoded App Store Connect distribution provisioning profile used to sign SeaLow.

The profile must match:

```text
Bundle ID:
com.shaferwebbconsulting.sealow
```

and the correct Apple Team ID.

---

## Step 1: Create or verify the App ID

Open:

**Apple Developer → Certificates, Identifiers & Profiles → Identifiers**

Create or verify the explicit App ID:

```text
com.shaferwebbconsulting.sealow
```

---

## Step 2: Create an App Store Connect provisioning profile

Open:

**Apple Developer → Certificates, Identifiers & Profiles → Profiles**

Click:

```text
+
```

Choose an App Store / App Store Connect distribution profile.

Select:

```text
com.shaferwebbconsulting.sealow
```

Select the Apple Distribution certificate created earlier.

Give it a name such as:

```text
SeaLow App Store
```

Download the resulting `.mobileprovision` file.

Example:

```text
SeaLow_App_Store.mobileprovision
```

---

## Step 3: Base64-encode the provisioning profile

On Linux:

```bash
openssl base64 \
  -A \
  -in SeaLow_App_Store.mobileprovision \
  -out profile_base64.txt
```

Validate it:

```bash
python3 - <<'PY'
from pathlib import Path
import base64

s = Path("profile_base64.txt").read_text()

print("Length:", len(s))
print("Modulo 4:", len(s) % 4)
print("Newlines:", s.count("\n"))

base64.b64decode(s, validate=True)

print("Base64 validation: PASS")
PY
```

---

## Step 4: Create the GitHub secret

Create:

```text
IOS_PROVISIONING_PROFILE_BASE64
```

Paste the entire contents of:

```text
profile_base64.txt
```

---

# Non-Secret Workflow Environment Variables

These values are normally defined directly in the GitHub Actions YAML because they are not secret.

---

## `APPLE_TEAM_ID`

Current SeaLow value:

```text
ZGF3WKWZVS
```

### What it is

Your Apple Developer Team ID.

You can find it in the Apple Developer account membership information.

Example workflow configuration:

```yaml
env:
  APPLE_TEAM_ID: "ZGF3WKWZVS"
```

---

## `BUNDLE_ID`

Current SeaLow value:

```text
com.shaferwebbconsulting.sealow
```

### What it is

The unique identifier for the SeaLow iOS application.

It must match:

- the Apple Developer App ID
- the provisioning profile
- the Godot iOS export configuration
- the App Store Connect application record

Example:

```yaml
env:
  BUNDLE_ID: "com.shaferwebbconsulting.sealow"
```

---

## `SCHEME`

Current value:

```text
SeaLow
```

### What it is

The Xcode scheme generated by the Godot iOS exporter.

Example:

```yaml
env:
  SCHEME: "SeaLow"
```

---

## `IOS_BUILD_NUMBER`

The workflow automatically sets:

```yaml
IOS_BUILD_NUMBER: ${{ github.run_number }}
```

### What it does

Every GitHub Actions run gets a numeric run number.

The workflow uses that value as the iOS build number (`CFBundleVersion`).

For example:

```text
GitHub run 12 → SeaLow 0.2 (12)
GitHub run 13 → SeaLow 0.2 (13)
GitHub run 14 → SeaLow 0.2 (14)
```

This prevents App Store Connect from rejecting repeated uploads because the build number was reused.

You normally do not need to create this variable manually.

---

# App Version vs Build Number

Godot uses two related values:

```ini
application/short_version="0.2"
application/version="14"
```

These correspond conceptually to:

```text
Version: 0.2
Build: 14
```

The pipeline leaves the release version alone:

```text
0.2
```

but replaces the build number automatically using:

```text
github.run_number
```

For normal development iterations:

```text
0.2 (14)
0.2 (15)
0.2 (16)
```

When a new product version is desired, update:

```ini
application/short_version="0.3"
```

or eventually:

```ini
application/short_version="1.0"
```

The GitHub build number can continue increasing.

---

# Complete Secret Checklist

Before running the workflow, GitHub should contain:

```text
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_PRIVATE_KEY
IOS_CERTIFICATE_BASE64
IOS_CERTIFICATE_PASSWORD
IOS_PROVISIONING_PROFILE_BASE64
```

The workflow YAML contains:

```text
APPLE_TEAM_ID
BUNDLE_ID
SCHEME
IOS_BUILD_NUMBER
```

---

# Files That Must Never Be Committed

Add these types of files to `.gitignore` or otherwise keep them outside the repository:

```gitignore
*.p12
*.p8
*.cer
*.pem
*.key
*.csr
*.mobileprovision

certificate_base64.txt
profile_base64.txt

sealow_distribution.key
sealow_distribution.csr
sealow_distribution_macos.p12
```

The most sensitive files are:

```text
sealow_distribution.key
sealow_distribution_macos.p12
AuthKey_*.p8
```

Anyone who obtains these files plus the relevant credentials may be able to impersonate your signing or App Store Connect automation identity.

---

# Normal Development Workflow

After all secrets are configured, the normal SeaLow iOS iteration loop is:

```text
Make SeaLow code changes
        ↓
Commit / push changes
        ↓
Run the GitHub Actions iOS workflow
        ↓
GitHub run number becomes iOS build number
        ↓
Godot exports SeaLow
        ↓
Apple Distribution certificate signs the app
        ↓
Provisioning profile is applied
        ↓
SeaLow.ipa is generated
        ↓
IPA is validated with App Store Connect
        ↓
IPA is uploaded
        ↓
Apple processes the build
        ↓
Build appears in TestFlight
        ↓
Install / test on iPhone
```

You do not need to manually increment the build number for each TestFlight iteration.
