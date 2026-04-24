#!/usr/bin/env python3
"""
SSH Utils - Parse SSH connection and sync files
Usage: 
  ssh_utils sync local_path "ssh -p 58764 root@120.238.149.138 -L 8080:localhost:8080"
  ssh_utils nvim local_path remote_path "ssh -p 58764 root@120.238.149.138 -L 8080:localhost:8080"
  ssh_utils connect "ssh ubuntu@209.20.158.130"
"""

import sys
import os
import re
import shlex
import subprocess
import time
import tempfile
from pathlib import Path
from datetime import datetime


COMMANDS = {'sync', 'nvim', 'connect'}


def setup_ssh_agent():
    """Setup SSH agent and add common keys."""
    print("Setting up SSH agent...")

    if not os.environ.get('SSH_AUTH_SOCK'):
        print("Starting SSH agent...")
        result = subprocess.run(['ssh-agent', '-s'], capture_output=True, text=True)
        if result.returncode == 0:
            for line in result.stdout.split('\n'):
                if '=' in line and 'export' not in line:
                    key, value = line.split('=', 1)
                    value = value.rstrip(';').strip('"')
                    os.environ[key] = value

    ssh_dir = Path.home() / '.ssh'
    for key_name in ['id_rsa', 'id_ed25519', 'id_ecdsa']:
        key_path = ssh_dir / key_name
        if key_path.exists():
            try:
                subprocess.run(['ssh-add', str(key_path)], check=False)
                print(f"Added SSH key: {key_name}")
            except subprocess.CalledProcessError:
                pass

    print("SSH agent setup complete")


def parse_cli_args(argv):
    """Parse CLI args."""
    if len(argv) < 3:
        raise ValueError("Not enough arguments")

    command = argv[1]
    args = argv[2:-1]
    ssh_command = argv[-1]

    if command not in COMMANDS:
        raise ValueError(f"Unknown command '{command}'")

    return command, args, ssh_command

class SSHParser:
    """Parse SSH connection strings with provider hints"""
    
    def __init__(self):
        self.connection_info = {}
    
    def parse_ssh_command(self, ssh_command):
        """Parse SSH command string and extract connection details"""
        print(f"Parsing SSH command: {ssh_command}")
        
        # Initialize defaults
        self.connection_info = {
            'host': None,
            'user': None,
            'port': 22,
            'port_forwards': [],
            'options': []
        }
        
        return self._parse_generic_ssh(ssh_command)
    
    def _parse_generic_ssh(self, ssh_command):
        """Parse generic SSH commands"""
        try:
            tokens = shlex.split(ssh_command)
        except ValueError as e:
            raise ValueError(f"Invalid SSH command: {e}")

        if not tokens or tokens[0] != 'ssh':
            raise ValueError("SSH command must start with 'ssh'")

        i = 1
        while i < len(tokens):
            token = tokens[i]

            if token == '-p' and i + 1 < len(tokens):
                self.connection_info['port'] = int(tokens[i + 1])
                i += 2
                continue

            if token == '-L' and i + 1 < len(tokens):
                port_forward = tokens[i + 1]
                parts = port_forward.split(':', 2)
                if len(parts) == 3 and parts[0].isdigit() and parts[2].isdigit():
                    local_port, bind_host, remote_port = parts
                    self.connection_info['port_forwards'].append({
                        'local_port': int(local_port),
                        'bind_host': bind_host,
                        'remote_port': int(remote_port)
                    })
                i += 2
                continue

            if token.startswith('-'):
                i += 1
                continue

            if '@' in token:
                user, host = token.split('@', 1)
                if user and host:
                    self.connection_info['user'] = user
                    self.connection_info['host'] = host
                    i += 1
                    continue

            i += 1

        return self._validate_connection_info()
    
    def _validate_connection_info(self):
        """Validate that we have minimum required connection info"""
        if not self.connection_info['host'] or not self.connection_info['user']:
            raise ValueError("Could not parse user@host from SSH command")
        
        print("Parsed SSH connection:")
        print(f"  Host: {self.connection_info['host']}")
        print(f"  User: {self.connection_info['user']}")
        print(f"  Port: {self.connection_info['port']}")
        
        if self.connection_info['port_forwards']:
            print("  Port Forwards:")
            for pf in self.connection_info['port_forwards']:
                print(f"    {pf['local_port']}:{pf['bind_host']}:{pf['remote_port']}")
            
        return self.connection_info

class SSHConnector:
    """Simple SSH connection class for direct terminal sessions"""
    
    def __init__(self, connection_info):
        self.conn = connection_info
    
    def connect(self):
        """Connect to SSH session with port forwarding if specified"""
        print(f"Connecting to {self.conn['user']}@{self.conn['host']}:{self.conn['port']}")
        
        # Build SSH command
        ssh_cmd = [
            'ssh',
            '-p', str(self.conn['port']),
            '-o', 'StrictHostKeyChecking=no',
            '-t'  # Force pseudo-terminal allocation
        ]
        
        # Add port forwarding if present
        for pf in self.conn['port_forwards']:
            ssh_cmd.extend(['-L', f"{pf['local_port']}:{pf['bind_host']}:{pf['remote_port']}"])
        
        # Add the user@host
        ssh_cmd.append(f"{self.conn['user']}@{self.conn['host']}")
        
        # Start a login shell and disable auto-tmux when supported.
        ssh_cmd.append('touch ~/.no_auto_tmux 2>/dev/null || true; TERM=xterm-256color bash -l')
        
        print(f"Executing: {' '.join(ssh_cmd)}")
        
        # Set TERM environment variable for compatibility
        env = os.environ.copy()
        env['TERM'] = 'xterm-256color'
        
        # Execute SSH command (this will replace the current process)
        try:
            os.execvpe('ssh', ssh_cmd, env)
        except OSError as e:
            print(f"Failed to execute SSH: {e}")
            sys.exit(1)

class SSHUtils:
    """Main SSH utilities class"""
    
    def __init__(self, connection_info, local_folder):
        self.conn = connection_info
        self.local_folder = Path(local_folder)
        
        # Root-based hosts such as Vast often expect syncs in the current work dir.
        if self.conn['user'] == 'root':
            self.remote_path = f"{self.local_folder.name}"
        else:
            self.remote_path = f"/home/{self.conn['user']}/sync"
        
        if not self.local_folder.exists():
            raise FileNotFoundError(f"Local folder does not exist: {local_folder}")
    
    def test_ssh_connection(self):
        """Test SSH connection"""
        print("Testing SSH connection...")
        
        cmd = [
            'ssh', 
            '-p', str(self.conn['port']),
            '-o', 'ConnectTimeout=10',
            '-o', 'StrictHostKeyChecking=no',
            f"{self.conn['user']}@{self.conn['host']}",
            "echo 'SSH connection successful'"
        ]
        
        try:
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("SSH connection test passed")
            return True
        except subprocess.CalledProcessError as e:
            print(f"SSH connection failed: {e}")
            print(f"Error output: {e.stderr}")
            return False
    
    def setup_remote_directory(self, remote_path=None):
        """Create remote directory if it doesn't exist"""
        if remote_path:
            self.remote_path = remote_path
        
        print(f"Setting up remote directory: {self.remote_path}")
        
        cmd = [
            'ssh',
            '-p', str(self.conn['port']),
            '-o', 'StrictHostKeyChecking=no',
            f"{self.conn['user']}@{self.conn['host']}",
            f"mkdir -p '{self.remote_path}'"
        ]
        
        try:
            subprocess.run(cmd, check=True, capture_output=True)
            print(f"Remote directory ready: {self.remote_path}")
            return True
        except subprocess.CalledProcessError as e:
            print(f"Failed to create remote directory: {e}")
            return False
    
    def sync_to_remote(self):
        """Sync ONLY git-tracked files to remote using rsync"""
        print(f"Syncing local → remote at {datetime.now()}")

        git_dir = self.local_folder / '.git'
        if not git_dir.exists():
            print(f"Error: {self.local_folder} is not a git repository (no .git directory).")
            print("Aborting sync. Only git-tracked sync is allowed.")
            return False

        temp_file = None

        try:
            # Get git tracked files (NUL-delimited for safety)
            git_result = subprocess.run(
                ['git', 'ls-files', '-z'],
                cwd=self.local_folder,
                capture_output=True,
                check=True
            )

            # Filter out tracked files missing from the working tree.
            tracked_entries = [entry for entry in git_result.stdout.split(b'\0') if entry]
            existing_entries = []
            missing_entries = []

            for entry in tracked_entries:
                rel_path = entry.decode('utf-8', errors='surrogateescape')
                abs_path = self.local_folder / rel_path
                if os.path.lexists(abs_path):
                    existing_entries.append(entry)
                else:
                    missing_entries.append(rel_path)

            if missing_entries:
                print(
                    "Warning: Skipping "
                    f"{len(missing_entries)} tracked files missing locally."
                )
                preview = missing_entries[:5]
                for path in preview:
                    print(f"  - {path}")
                if len(missing_entries) > len(preview):
                    print(f"  ... and {len(missing_entries) - len(preview)} more")

            if not existing_entries:
                print("No existing tracked files to sync.")
                return True

            # Create temporary file with filtered tracked files
            with tempfile.NamedTemporaryFile(mode='wb', delete=False) as f:
                f.write(b'\0'.join(existing_entries) + b'\0')
                temp_file = f.name

            rsync_cmd = [
                'rsync', '-azvv',
                '--from0',
                f'--files-from={temp_file}',
                '--exclude=.git/',
                '--exclude=.git*',
                '--exclude=node_modules/',
                '--exclude=__pycache__/',
                '--exclude=*.pyc',
                '-e', f'ssh -p {self.conn["port"]} -o StrictHostKeyChecking=no',
                f'{self.local_folder}/',
                f'{self.conn["user"]}@{self.conn["host"]}:{self.remote_path}'
            ]

            # Ensure SSH agent environment is inherited
            env = os.environ.copy()
            rsync_result = subprocess.run(rsync_cmd, env=env)
            if rsync_result.returncode != 0:
                print(f"Error: rsync failed with exit code {rsync_result.returncode}.")
                return False

            print("Sync completed successfully")
            return True

        except subprocess.CalledProcessError as e:
            print("Error: 'git ls-files' failed, aborting sync.")
            if e.stderr:
                print(e.stderr.decode('utf-8', errors='replace'))
            return False

        except Exception as e:
            print(f"Sync failed with unexpected error: {e}")
            return False

        finally:
            if temp_file is not None and os.path.exists(temp_file):
                os.unlink(temp_file)
    
    def start_file_monitor(self):
        """Start file monitoring daemon using inotifywait"""
        print(f"Starting file monitoring daemon for {self.local_folder}")
        print("Press Ctrl+C to stop")
        
        while True:
            print("Waiting for file changes...")
            
            # Use inotifywait to monitor changes
            cmd = [
                'inotifywait', '-r', '-q', '-t', '30',
                '-e', 'modify,create,moved_to,attrib,close_write',
                '--exclude', r'\.git/.*|4913$|\.swp$|\.sw[a-z]$|\.netrwhist|__pycache__|\.pyc$',
                '--format', '%w%f',
                str(self.local_folder)
            ]
            
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=35)
                
                if result.returncode == 0 and result.stdout.strip():
                    changed_file = result.stdout.strip()
                    print(f"File changed: {changed_file}")
                    print("Triggering sync...")
                    self.sync_to_remote()
                else:
                    print("No changes detected in the last 30 seconds")
                
            except subprocess.TimeoutExpired:
                print("No changes detected (timeout)")
            except KeyboardInterrupt:
                print("\nStopping ssh_utils...")
                break
            
            # Small delay to prevent excessive syncing
            time.sleep(1)

def main():
    """Main function"""
    if len(sys.argv) < 3:
        print("Usage:")
        print("  ssh_utils [command] [args...] \"ssh_command\"")
        print("")
        print("Commands:")
        print("  sync     - Sync local folder to remote and monitor changes")
        print("  nvim     - Sync local folder to remote path and monitor changes")
        print("  connect  - Just connect to SSH session")
        print("")
        print("Examples:")
        print("  ssh_utils connect \"ssh ubuntu@209.20.158.130\"")
        print("  ssh_utils sync /local/path \"ssh root@host -p 58764 -L 8080:localhost:8080\"")
        print("  ssh_utils nvim /local/path /remote/path \"ssh ubuntu@host\"")
        sys.exit(1)

    try:
        command, args, ssh_command = parse_cli_args(sys.argv)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    if command == "connect":
        if len(args) != 0:
            print("Error: connect command format: ssh_utils connect \"ssh_command\"")
            sys.exit(1)
        
        print("SSH Utils - Connect Mode")
        print(f"SSH Command: {ssh_command}")
        print()
        
        try:
            # Parse SSH command
            parser = SSHParser()
            connection_info = parser.parse_ssh_command(ssh_command)
            
            # Initialize SSH connector
            ssh_connector = SSHConnector(connection_info)
            
            setup_ssh_agent()
            
            # Connect (this will replace the current process)
            ssh_connector.connect()
            
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
    
    elif command == "nvim":
        if len(args) != 2:
            print("Error: nvim command format: ssh_utils nvim local_path remote_path \"ssh_command\"")
            sys.exit(1)
        
        local_folder, remote_path = args
        
        print("SSH Utils - Nvim Mode (Sync + Connect)")
        print(f"SSH Command: {ssh_command}")
        print(f"Local Folder: {local_folder}")
        print(f"Remote Path: {remote_path}")
        print()
        
        try:
            # Parse SSH command
            parser = SSHParser()
            connection_info = parser.parse_ssh_command(ssh_command)
            
            # Initialize SSH utils for syncing
            ssh_utils = SSHUtils(connection_info, local_folder)
            # Override the remote path with the user-specified one
            ssh_utils.remote_path = remote_path
            
            setup_ssh_agent()
            
            # Test connection
            if not ssh_utils.test_ssh_connection():
                print("SSH connection test failed. Exiting.")
                sys.exit(1)
            
            # Setup remote directory
            ssh_utils.setup_remote_directory(remote_path)
            
            # Perform initial sync
            print("Performing initial sync...")
            if not ssh_utils.sync_to_remote():
                print("Initial sync failed. Exiting.")
                sys.exit(1)
            
            print("Sync completed successfully.")
            print()
            print("=== NVIM MODE ===")
            print("This will start continuous file monitoring and syncing.")
            print("Your local changes will be automatically synced to the remote server.")
            print("Press Ctrl+C to stop the sync and exit.")
            print()
            
            # Start continuous file monitoring
            ssh_utils.start_file_monitor()
            
        except KeyboardInterrupt:
            print("\nStopping ssh_utils...")
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
    
    elif command == "sync":
        if len(args) != 1:
            print("Error: sync command format: ssh_utils sync local_path \"ssh_command\"")
            sys.exit(1)
        
        local_folder = args[0]
        
        print("SSH Utils - Sync Mode")
        print(f"SSH Command: {ssh_command}")
        print(f"Local Folder: {local_folder}")
        print()
        
        try:
            # Parse SSH command
            parser = SSHParser()
            connection_info = parser.parse_ssh_command(ssh_command)
            
            # Initialize SSH utils
            ssh_utils = SSHUtils(connection_info, local_folder)
            
            setup_ssh_agent()
            
            # Test connection
            if not ssh_utils.test_ssh_connection():
                print("SSH connection test failed. Exiting.")
                sys.exit(1)
            
            # Setup remote directory
            ssh_utils.setup_remote_directory()
            
            # Perform initial sync
            print("Performing initial sync...")
            ssh_utils.sync_to_remote()
            
            # Start file monitoring
            ssh_utils.start_file_monitor()
            
        except KeyboardInterrupt:
            print("\nStopping ssh_utils...")
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
    
    else:
        print(f"Error: Unknown command '{command}'")
        print("Available commands: sync, nvim, connect")
        sys.exit(1)

if __name__ == "__main__":
    main()
