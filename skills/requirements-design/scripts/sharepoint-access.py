#!/usr/bin/env python3
"""
SharePoint Access Script for Requirements Design

Access SharePoint documents via Microsoft Graph API using Azure CLI authentication.

Usage:
    # List folder contents
    python sharepoint-access.py --url "https://company.sharepoint.com/sites/..." --action list

    # Download file
    python sharepoint-access.py --url "https://company.sharepoint.com/.../file.docx" --action download --output ./docs/

    # Get file metadata
    python sharepoint-access.py --url "https://company.sharepoint.com/.../file.docx" --action metadata

Requirements:
    - Azure CLI installed (`az`)
    - Authenticated with `az login --allow-no-subscriptions --tenant <tenant-id>`
    - Permissions to access SharePoint site
"""

import argparse
import json
import subprocess
import sys
import urllib.parse
from pathlib import Path
from typing import Optional, Tuple


class SharePointAccess:
    """Access SharePoint via Microsoft Graph API"""

    def __init__(self, url: str):
        self.url = url
        self.hostname, self.site_path, self.item_path = self._parse_url(url)
        self.site_id: Optional[str] = None
        self.drive_id: Optional[str] = None
        self.access_token: Optional[str] = None

    def _parse_url(self, url: str) -> Tuple[str, str, str]:
        """
        Parse SharePoint URL to extract hostname, site path, and item path.

        Examples:
            https://company.sharepoint.com/sites/SiteName/Shared Documents/folder/file.docx
            -> ('company.sharepoint.com', '/sites/SiteName', '/Shared Documents/folder/file.docx')
        """
        parsed = urllib.parse.urlparse(url)
        hostname = parsed.netloc

        # Decode URL-encoded path
        full_path = urllib.parse.unquote(parsed.path)

        # Extract site path (e.g., /sites/SiteName)
        if '/sites/' in full_path:
            parts = full_path.split('/sites/', 1)
            if len(parts) > 1:
                site_parts = parts[1].split('/', 1)
                site_path = f"/sites/{site_parts[0]}"
                item_path = f"/{site_parts[1]}" if len(site_parts) > 1 else ""
            else:
                site_path = ""
                item_path = full_path
        else:
            site_path = ""
            item_path = full_path

        # Handle "Documents partages" (Shared Documents) and similar library names
        # Extract from "id=" parameter if present
        if 'id=' in url:
            id_param = url.split('id=')[1].split('&')[0]
            id_decoded = urllib.parse.unquote(id_param)
            if id_decoded.startswith('/sites/'):
                # Extract site and path from id parameter
                id_parts = id_decoded.split('/', 4)  # ['', 'sites', 'SiteName', 'Library', 'path']
                if len(id_parts) >= 4:
                    site_path = f"/{id_parts[1]}/{id_parts[2]}"
                    item_path = f"/{'/'.join(id_parts[3:])}" if len(id_parts) > 3 else ""

        return hostname, site_path, item_path

    def _run_az_command(self, args: list) -> Tuple[bool, str]:
        """Run Azure CLI command and return (success, output)"""
        try:
            result = subprocess.run(
                ['az'] + args,
                capture_output=True,
                text=True,
                check=False
            )
            if result.returncode == 0:
                return True, result.stdout.strip()
            else:
                return False, result.stderr.strip()
        except FileNotFoundError:
            return False, "Azure CLI not found. Please install it first."
        except Exception as e:
            return False, str(e)

    def check_az_installed(self) -> bool:
        """Check if Azure CLI is installed"""
        success, output = self._run_az_command(['version'])
        if not success:
            print("❌ Azure CLI not installed.")
            print("\nInstall Azure CLI:")
            print("  Linux:   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash")
            print("  macOS:   brew install azure-cli")
            print("  Windows: https://aka.ms/installazurecliwindows")
            return False
        return True

    def get_access_token(self) -> bool:
        """Get Microsoft Graph API access token from Azure CLI"""
        success, output = self._run_az_command([
            'account', 'get-access-token',
            '--resource=https://graph.microsoft.com',
            '--query', 'accessToken',
            '-o', 'tsv'
        ])

        if not success:
            print("❌ Not authenticated to Azure.")
            print("\nAuthenticate with:")
            print(f"  az login --allow-no-subscriptions")
            print("\nIf tenant mismatch, use:")
            print(f"  az login --allow-no-subscriptions --tenant <tenant-id>")
            return False

        self.access_token = output
        return True

    def _graph_api_call(self, endpoint: str) -> Optional[dict]:
        """Make Microsoft Graph API call"""
        import requests

        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Accept': 'application/json'
        }

        try:
            response = requests.get(f'https://graph.microsoft.com/v1.0{endpoint}', headers=headers)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Graph API error: {e}")
            if hasattr(e.response, 'text'):
                print(f"Response: {e.response.text}")
            return None

    def get_site(self) -> bool:
        """Get SharePoint site ID"""
        endpoint = f"/sites/{self.hostname}:{self.site_path}"
        data = self._graph_api_call(endpoint)

        if not data:
            print(f"❌ Could not access site: {self.hostname}{self.site_path}")
            print("\nPossible issues:")
            print("  - Tenant mismatch (use correct `az login --tenant <id>`)")
            print("  - No permission to access this site")
            print("  - Site path incorrect")
            return False

        self.site_id = data.get('id')
        print(f"✅ Site: {data.get('displayName')} ({data.get('name')})")
        return True

    def get_drives(self) -> bool:
        """Get document libraries (drives) for the site"""
        endpoint = f"/sites/{self.site_id}/drives"
        data = self._graph_api_call(endpoint)

        if not data or 'value' not in data:
            print("❌ Could not get document libraries")
            return False

        drives = data['value']
        if not drives:
            print("❌ No document libraries found")
            return False

        # Use first drive (typically "Documents" / "Shared Documents")
        self.drive_id = drives[0]['id']
        print(f"✅ Library: {drives[0]['name']}")
        return True

    def list_folder(self, path: str = None) -> bool:
        """List contents of folder"""
        if path is None:
            path = self.item_path

        # Remove library name from path if present
        # Path should be relative to drive root
        path_parts = path.strip('/').split('/', 1)
        if len(path_parts) > 1:
            relative_path = path_parts[1]
        else:
            relative_path = ""

        if relative_path:
            endpoint = f"/drives/{self.drive_id}/root:/{relative_path}:/children"
        else:
            endpoint = f"/drives/{self.drive_id}/root/children"

        data = self._graph_api_call(endpoint)

        if not data or 'value' not in data:
            print(f"❌ Could not list folder: {path}")
            return False

        items = data['value']
        print(f"\n📁 Folder: {path}")
        print(f"Items: {len(items)}\n")

        # Separate folders and files
        folders = [item for item in items if 'folder' in item]
        files = [item for item in items if 'file' in item]

        # Print folders
        if folders:
            print("Folders:")
            for item in sorted(folders, key=lambda x: x['name']):
                child_count = item['folder'].get('childCount', 0)
                size_mb = item.get('size', 0) / (1024 * 1024)
                print(f"  📁 {item['name']} ({child_count} items, {size_mb:.1f} MB)")

        # Print files
        if files:
            print("\nFiles:")
            for item in sorted(files, key=lambda x: x['name']):
                size_kb = item.get('size', 0) / 1024
                modified = item.get('lastModifiedDateTime', 'Unknown')[:10]
                print(f"  📄 {item['name']} ({size_kb:.1f} KB, modified: {modified})")

        return True

    def download_file(self, output_dir: str = ".") -> bool:
        """Download file from SharePoint"""
        import requests

        # Get file metadata first
        path_parts = self.item_path.strip('/').split('/', 1)
        if len(path_parts) > 1:
            relative_path = path_parts[1]
        else:
            relative_path = self.item_path.strip('/')

        endpoint = f"/drives/{self.drive_id}/root:/{relative_path}"
        data = self._graph_api_call(endpoint)

        if not data:
            print(f"❌ File not found: {self.item_path}")
            return False

        # Get download URL
        download_url = data.get('@microsoft.graph.downloadUrl')
        if not download_url:
            print("❌ No download URL available")
            return False

        # Download file
        filename = data['name']
        output_path = Path(output_dir) / filename

        print(f"⬇️  Downloading: {filename}")

        try:
            response = requests.get(download_url, stream=True)
            response.raise_for_status()

            with open(output_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            print(f"✅ Downloaded to: {output_path}")
            return True
        except Exception as e:
            print(f"❌ Download failed: {e}")
            return False

    def get_metadata(self) -> bool:
        """Get file/folder metadata"""
        path_parts = self.item_path.strip('/').split('/', 1)
        if len(path_parts) > 1:
            relative_path = path_parts[1]
        else:
            relative_path = self.item_path.strip('/')

        endpoint = f"/drives/{self.drive_id}/root:/{relative_path}"
        data = self._graph_api_call(endpoint)

        if not data:
            print(f"❌ Item not found: {self.item_path}")
            return False

        print("\n📋 Metadata:")
        print(f"  Name: {data.get('name')}")
        print(f"  Type: {'Folder' if 'folder' in data else 'File'}")
        print(f"  Size: {data.get('size', 0) / 1024:.1f} KB")
        print(f"  Created: {data.get('createdDateTime', 'Unknown')[:10]}")
        print(f"  Modified: {data.get('lastModifiedDateTime', 'Unknown')[:10]}")
        print(f"  Created By: {data.get('createdBy', {}).get('user', {}).get('displayName', 'Unknown')}")
        print(f"  Modified By: {data.get('lastModifiedBy', {}).get('user', {}).get('displayName', 'Unknown')}")
        print(f"  Web URL: {data.get('webUrl', 'Unknown')}")

        if 'folder' in data:
            print(f"  Child Count: {data['folder'].get('childCount', 0)}")

        return True


def main():
    parser = argparse.ArgumentParser(
        description='Access SharePoint documents via Microsoft Graph API',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--url', required=True, help='SharePoint URL')
    parser.add_argument('--action', choices=['list', 'download', 'metadata'], default='list',
                       help='Action to perform (default: list)')
    parser.add_argument('--output', default='.', help='Output directory for downloads (default: current directory)')

    args = parser.parse_args()

    # Initialize SharePoint access
    sp = SharePointAccess(args.url)

    print(f"🔗 SharePoint URL: {args.url}")
    print(f"📍 Parsed:")
    print(f"   Host: {sp.hostname}")
    print(f"   Site: {sp.site_path}")
    print(f"   Path: {sp.item_path}\n")

    # Check Azure CLI
    if not sp.check_az_installed():
        sys.exit(1)

    # Get access token
    if not sp.get_access_token():
        sys.exit(1)

    # Get site
    if not sp.get_site():
        sys.exit(1)

    # Get drives
    if not sp.get_drives():
        sys.exit(1)

    # Perform action
    if args.action == 'list':
        if not sp.list_folder():
            sys.exit(1)
    elif args.action == 'download':
        if not sp.download_file(args.output):
            sys.exit(1)
    elif args.action == 'metadata':
        if not sp.get_metadata():
            sys.exit(1)

    print("\n✅ Done!")


if __name__ == '__main__':
    main()
