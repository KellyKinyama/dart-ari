A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.

dart compile exe --target-os=linux --target-arch=x64 bin/dart_ari.dart

Skip to content
You said:
installing dart on oracle linux
ChatGPT said:
To install Dart on Oracle Linux (typically based on RHEL/CentOS), follow these steps based on your Oracle Linux version (usually OL8 or OL9):

✅ Step-by-step Guide for Oracle Linux 8 or 9
1. Enable the Dart APT/YUM repository
Dart provides a Yum repo compatible with RHEL-based distros, including Oracle Linux.

Create the repo file:

sudo tee /etc/yum.repos.d/dart.repo > /dev/null <<EOF
[dart]
name=Dart SDK
baseurl=https://storage.googleapis.com/download.dartlang.org/linux/fedora/$(rpm -E %fedora)/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF
Note: Dart does not provide official builds for Oracle Linux directly, but the Fedora repo often works. If you're unsure what %fedora expands to on Oracle Linux, you can manually set it to a compatible Fedora release. For OL8, use Fedora 34 or 35. For OL9, try Fedora 36+.

If the above doesn’t work due to %fedora, use:

sudo tee /etc/yum.repos.d/dart.repo > /dev/null <<EOF
[dart]
name=Dart SDK
baseurl=https://storage.googleapis.com/download.dartlang.org/linux/fedora/36/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF
2. Install Dart SDK
sudo dnf install dart
If you're on OL8 and dnf is not available, use:

sudo yum install dart
3. Verify installation
dart --version
✅ Alternative: Manual Installation
If the repo method doesn't work or is outdated:

# Download latest stable Dart SDK (64-bit)
wget https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip

# Unzip it somewhere
unzip dartsdk-linux-x64-release.zip -d ~/dart-sdk

# Add Dart to PATH
echo 'export PATH="$PATH:$HOME/dart-sdk/bin"' >> ~/.bashrc
source ~/.bashrc
Check with:

dart --version
Would you like a script that installs Dart automatically with all these steps on OL8 or OL9?

You said:
[root@ccivr-recorder ~]# sudo dnf install dart
Dart SDK                                                             78  B/s | 231  B     00:02
Errors during downloading metadata for repository 'dart':
  - Status code: 404 for https://storage.googleapis.com/download.dartlang.org/linux/fedora/%fedora/x86_64/repodata/repomd.xml (IP: 142.251.47.155)
Error: Failed to download metadata for repo 'dart': Cannot download repomd.xml: Cannot download repodata/repomd.xml: All mirrors were tried
[root@ccivr-recorder ~]#
ChatGPT said:
The error you're seeing:

Status code: 404 for https://storage.googleapis.com/download.dartlang.org/linux/fedora/%fedora/x86_64/repodata/repomd.xml
means that the %fedora macro in your repo file was not expanded—this usually happens on Oracle Linux since it doesn’t define that RPM macro.

✅ Fix: Hardcode the Fedora Version
On Oracle Linux 8, the most compatible Dart repo is usually Fedora 36.

Please do the following to fix the issue:

1. Edit the repo file
Run:

sudo nano /etc/yum.repos.d/dart.repo
Replace the contents with:

[dart]
name=Dart SDK
baseurl=https://storage.googleapis.com/download.dartlang.org/linux/fedora/36/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
Save and exit (Ctrl + O, Enter, Ctrl + X in nano).

2. Clean and try again
sudo dnf clean all
sudo dnf install dart
✅ If that still fails, use Manual Install
Here’s a reliable method that bypasses the repo:

# Go to your home directory or any working folder
cd ~

# Download latest stable Dart SDK for Linux x64
wget https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip

# Unzip the SDK
unzip dartsdk-linux-x64-release.zip -d dart-sdk

# Add Dart to PATH (for current shell)
export PATH="$PATH:$PWD/dart-sdk/dart-sdk/bin"

# To make it permanent for future sessions:
echo 'export PATH="$PATH:$HOME/dart-sdk/dart-sdk/bin"' >> ~/.bashrc
source ~/.bashrc
Then verify:

dart --version
Let me know if you'd like to make this into a shell script for easier reuse or deployment.

You said:
this is mu current directory
ChatGPT said:
Great! Please show me the output of:

pwd
This will tell me your current directory, so I can tailor the Dart installation path accordingly.

Also, run:

ls
to show what’s already in your current directory — just to avoid overwriting anything important during extraction.

Once you share that, I’ll give you the exact next steps to install Dart manually in your current working directory.

You said:
/usr/src
ChatGPT said:
Thanks! Since you're in /usr/src, which is a system directory, it's better to avoid installing Dart there directly — especially not as a non-packaged SDK — because:

/usr/src is usually reserved for kernel source and development headers.

It's not writable by non-root users.

It could be cleaned or overwritten during system updates.

✅ Recommended Dart Manual Installation Path
Instead of /usr/src, install Dart SDK in /opt/dart or under a regular user's home directory (like /home/youruser/dart-sdk).

But if you must install to /usr/src, you can — just be cautious.

🔧 Steps to Manually Install Dart SDK in /opt/dart
1. Create a directory:
sudo mkdir -p /opt/dart
cd /opt/dart
2. Download Dart SDK:
sudo curl -O https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip
3. Unzip it:
sudo unzip dartsdk-linux-x64-release.zip
This will create a dart-sdk folder inside /opt/dart.

4. Add Dart to PATH:
Edit the global profile (optional), or just set it in your shell:

echo 'export PATH=$PATH:/opt/dart/dart-sdk/bin' | sudo tee /etc/profile.d/dart.sh
sudo chmod +x /etc/profile.d/dart.sh
source /etc/profile.d/dart.sh
5. Test it:
dart --version
🛠 Alternate: Install to User Directory (if you want per-user access)
Instead of /usr/src or /opt, you could install to $HOME/dart-sdk:

cd ~
wget https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip
unzip dartsdk-linux-x64-release.zip -d dart-sdk
echo 'export PATH=$PATH:$HOME/dart-sdk/dart-sdk/bin' >> ~/.bashrc
source ~/.bashrc
dart --version
Would you like me to provide this as a single script you can copy and run?

You said:
[root@ccivr-recorder src]# dart --version
Dart SDK version: 3.8.1 (stable) (Wed May 28 00:47:25 2025 -0700) on "linux_x64"
ChatGPT said:
✅ Perfect — that means Dart SDK v3.8.1 is now successfully installed and available in your shell!

You’re ready to:

Run Dart programs (dart run)

Compile native executables (dart compile exe)

Create new projects (dart create my_app)

🧪 Quick Test
To verify it’s fully working:

mkdir ~/dart_test
cd ~/dart_test
echo 'void main() => print("Hello from Dart!");' > hello.dart
dart run hello.dart
Expected output:

Hello from Dart!
If you ever need help with using Dart or integrating it into a specific project (e.g., CLI tool, web server, database access, etc.), feel free to ask!




No file chosenNo file chosen
ChatGPT can make mistakes. Check important info.
