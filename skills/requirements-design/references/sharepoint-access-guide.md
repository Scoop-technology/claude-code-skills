# SharePoint Access Guide

Access SharePoint documents during requirements gathering using Microsoft Graph API via Azure CLI authentication.

---

## Quick Start

```bash
# 1. Authenticate to Azure (if not already)
az login --allow-no-subscriptions

# 2. List SharePoint folder contents
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://company.sharepoint.com/sites/SiteName/Shared Documents/folder" \
  --action list

# 3. Download file
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://company.sharepoint.com/sites/SiteName/Shared Documents/file.docx" \
  --action download \
  --output ./docs/
```

---

## Prerequisites

### 1. Install Azure CLI

**Linux (Ubuntu/Debian):**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Linux (RPM-based - RHEL, CentOS, Fedora):**
```bash
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install -y azure-cli
```

**macOS:**
```bash
brew install azure-cli
```

**Windows:**
- Download installer: https://aka.ms/installazurecliwindows
- Or via winget: `winget install -e --id Microsoft.AzureCLI`

**Verify installation:**
```bash
az version
```

### 2. Install Python Dependencies

```bash
pip install requests
```

---

## Authentication

### Basic Authentication

```bash
# Login to Azure
az login --allow-no-subscriptions
```

This opens a browser for authentication. Complete the login process.

### Multi-Tenant Scenarios

If the SharePoint site is in a different tenant than your default:

```bash
# List available tenants
az account list

# Login to specific tenant
az login --allow-no-subscriptions --tenant <tenant-id>
```

**Finding Tenant ID:**
- SharePoint URL: `https://company.sharepoint.com` → Tenant is "company"
- From error messages: Script will show "Invalid hostname for this tenancy" with details
- From Azure Portal: Azure Active Directory → Properties → Tenant ID

### Verify Authentication

```bash
# Check current account
az account show

# Get access token (test)
az account get-access-token --resource=https://graph.microsoft.com
```

---

## Usage

### List Folder Contents

```bash
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://company.sharepoint.com/sites/SiteName/Shared Documents/Project/Requirements" \
  --action list
```

**Output:**
```
✅ Site: Project Name (SiteName)
✅ Library: Documents

📁 Folder: /Shared Documents/Project/Requirements
Items: 12

Folders:
  📁 Architecture Diagrams (5 items, 15.2 MB)
  📁 User Research (8 items, 3.4 MB)

Files:
  📄 Product Requirements.docx (145.3 KB, modified: 2026-01-15)
  📄 Technical Constraints.md (12.4 KB, modified: 2026-01-18)
  📄 User Stories.xlsx (89.2 KB, modified: 2026-01-20)
```

### Download File

```bash
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://company.sharepoint.com/sites/SiteName/Shared Documents/requirements.docx" \
  --action download \
  --output ./docs/Design/
```

**Output:**
```
⬇️  Downloading: requirements.docx
✅ Downloaded to: ./docs/Design/requirements.docx
```

### Get File/Folder Metadata

```bash
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://company.sharepoint.com/sites/SiteName/Shared Documents/file.docx" \
  --action metadata
```

**Output:**
```
📋 Metadata:
  Name: requirements.docx
  Type: File
  Size: 145.3 KB
  Created: 2026-01-15
  Modified: 2026-01-20
  Created By: John Smith
  Modified By: Jane Doe
  Web URL: https://company.sharepoint.com/.../requirements.docx
```

---

## SharePoint URL Formats

The script handles various SharePoint URL formats:

### Direct Path URL
```
https://company.sharepoint.com/sites/SiteName/Shared Documents/folder/file.docx
```

### SharePoint UI URL (with query parameters)
```
https://company.sharepoint.com/sites/SiteName/Documents%20partages/Forms/AllItems.aspx?id=%2Fsites%2FSiteName%2FDocuments%20partages%2Ffolder%2Ffile.docx
```

### URL-Encoded Paths
```
https://company.sharepoint.com/sites/SiteName/Shared%20Documents/My%20Folder/file.docx
```

The script automatically:
- Decodes URL-encoded characters
- Extracts site name and path
- Handles "Documents partages" (French for Shared Documents)
- Parses `id=` parameter if present

---

## Common Issues

### Issue: "Azure CLI not found"

**Solution:**
```bash
# Install Azure CLI (see Prerequisites section above)

# Verify installation
az version
```

### Issue: "Not authenticated to Azure"

**Solution:**
```bash
# Login to Azure
az login --allow-no-subscriptions

# If specific tenant needed
az login --allow-no-subscriptions --tenant <tenant-id>
```

### Issue: "Invalid hostname for this tenancy"

**Cause:** Authenticated to wrong tenant

**Solution:**
```bash
# Check current tenant
az account show

# Login to correct tenant
az login --allow-no-subscriptions --tenant <correct-tenant-id>
```

**Finding correct tenant ID:**
1. Look at SharePoint URL: `https://argonconsult.sharepoint.com` → Try tenant "argonconsult"
2. Check with organization admin
3. Try `az login` without tenant - select correct one from list

### Issue: "Could not access site" or "No permission"

**Causes:**
- No permission to access SharePoint site
- Site path incorrect
- Graph API permissions not granted

**Solutions:**
```bash
# Verify site URL is correct
# Check with site owner for access
# Ensure you're member of the SharePoint site

# Re-authenticate
az logout
az login --allow-no-subscriptions --tenant <tenant-id>
```

### Issue: "File not found"

**Causes:**
- File path incorrect
- File moved or deleted
- Library name wrong (e.g., "Documents" vs "Documents partages")

**Solutions:**
1. List parent folder first to verify path:
   ```bash
   python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
     --url "https://company.sharepoint.com/sites/SiteName/Shared Documents/folder" \
     --action list
   ```

2. Use exact file name from list output
3. Check SharePoint UI for correct path

---

## Workflow Integration

### During Requirements Gathering

When user provides SharePoint location for documentation:

1. **Document the location cleanly:**
   ```markdown
   **Documentation Location:**
   - Platform: SharePoint Online
   - Site: IRISAPACSales
   - Library: Shared Documents
   - Folder: /General/Alliance Group/1.0 Client data
   - Clean URL: https://argonconsult.sharepoint.com/sites/IRISAPACSales/Shared Documents/General/Alliance Group/1.0 Client data
   ```

2. **List existing documents:**
   ```bash
   python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
     --url "<sharepoint-url>" \
     --action list
   ```

3. **Download relevant files:**
   ```bash
   # Download to local docs directory
   python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
     --url "<file-url>" \
     --action download \
     --output ./docs/Reference/
   ```

4. **Reference in requirements:**
   ```markdown
   ## References

   - [Gareth's Alliance Group Notes](../Reference/Gareth's Alliance Group Notes.docx) - Downloaded from SharePoint
   - [Process mapping diagram](../Reference/Livestock E2E process mapping.pdf) - SharePoint reference
   ```

### Example: Alliance Group Project

```bash
# 1. Authenticate to ARGON&CO tenant
az login --allow-no-subscriptions --tenant f85b23bd-1472-4658-b2cd-bff744680942

# 2. List client data folder
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://argonconsult.sharepoint.com/sites/IRISAPACSales/Documents%20partages/General/Alliance%20Group/1.0%20Client%20data" \
  --action list

# 3. Download Gareth's notes
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://argonconsult.sharepoint.com/sites/IRISAPACSales/Documents%20partages/General/Alliance%20Group/1.0%20Client%20data/Gareth's%20Alliance%20Group%20Notes.docx" \
  --action download \
  --output ./docs/Reference/

# 4. Download process mapping
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "https://argonconsult.sharepoint.com/sites/IRISAPACSales/Documents%20partages/General/Alliance%20Group/1.0%20Client%20data/Copy%20of%20Livestock%20E2E%20process%20mapping%20Jul%202025%20-%20Detailed%20workflow.pdf" \
  --action download \
  --output ./docs/Reference/
```

---

## Tips

### 1. Save SharePoint URLs Cleanly

When user provides messy SharePoint URL with query parameters, clean it up for constraints:

**Messy URL:**
```
https://company.sharepoint.com/sites/Site/Documents%20partages/Forms/AllItems.aspx?id=%2Fsites%2FSite%2FDocuments%20partages%2Ffolder&viewid=abc123
```

**Clean URL for constraints:**
```
https://company.sharepoint.com/sites/Site/Shared Documents/folder
```

The script handles both formats, but clean URLs are more readable in documentation.

### 2. Download Before Creating Requirements

If SharePoint has existing requirements docs:
1. Download them first
2. Review content
3. Reference in new requirements
4. Avoid duplicating work

### 3. Organize Downloaded Files

```bash
# Create reference directory
mkdir -p docs/Reference/SharePoint

# Download files there
python ~/.claude/skills/requirements-design/scripts/sharepoint-access.py \
  --url "<url>" \
  --action download \
  --output ./docs/Reference/SharePoint/
```

### 4. Handle Large Folders

For folders with many files, list first to identify what's needed:
```bash
# List folder
python ... --action list

# Download only needed files
python ... --url "<specific-file-url>" --action download
```

---

## Security Notes

- **Tokens expire**: Azure CLI tokens are valid for ~1 hour. Re-authenticate if needed.
- **Permissions**: Script can only access what your account can access in SharePoint
- **No credentials stored**: Uses Azure CLI authentication, no passwords in scripts
- **Tenant isolation**: Can only access SharePoint sites in authenticated tenant

---

## Troubleshooting Checklist

- [ ] Azure CLI installed? (`az version`)
- [ ] Authenticated? (`az account show`)
- [ ] Correct tenant? (Check tenant ID in `az account show`)
- [ ] SharePoint URL correct? (Try accessing in browser first)
- [ ] Have permission to SharePoint site? (Check with site owner)
- [ ] Python `requests` library installed? (`pip install requests`)
- [ ] Network connectivity to SharePoint? (Behind corporate firewall?)

---

## Further Reading

- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [SharePoint Sites API Reference](https://docs.microsoft.com/en-us/graph/api/resources/sharepoint)
