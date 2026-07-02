# GeckOS

A lightweight Linux server management panel. Out of the box, manage all your daily server operations right from the browser.

## Modules

### 🖥️ Web Terminal
A full-featured browser terminal. Access your server from anywhere via the web, with multi-session, Unicode input, and copy/paste support — no SSH client required.

### 📁 File Manager
A visual file manager supporting browse, upload (resumable), download, edit, extract, and batch operations. Multiple disks at a glance.

### 🐳 Docker Management
Complete management of containers, images, and volumes. Start/stop, view logs, port mapping, and compose deployment — manage Docker without the command line.

### 📊 System Monitor
Real-time monitoring and historical trends for CPU, memory, disk, and network. Keep track of your host's health and catch issues early.

### ⚙️ Process Manager
View and manage system processes, inspect resource usage, and terminate misbehaving processes.

### 📝 System Logs
Real-time log streaming. No more `tail -f` — follow system activity directly in the browser.

### 🏪 App Store
One-click deploy Docker applications — Nginx, MySQL, Redis, WordPress, and more. Browse by category, configure environment variables, and watch real-time install progress.

### 🔌 Plugin System
A rich plugin ecosystem to extend the panel. Install plugins from the marketplace to add features on demand.

### 📱 Multi-Platform
Web + mobile (iOS / Android). Manage your server from your phone with ease.

## Highlights

- **Zero Config**: Install and run, no complex setup required
- **Lightweight**: Single binary, minimal resource footprint — fits servers and embedded devices of any size
- **Secure**: JWT authentication, forced default password change, auto-generated config
- **Modern UI**: Responsive design, adapts to desktop and mobile
- **Plugin Architecture**: Install only what you need, keep the core lean

## Quick Start

```bash
# One-line install
curl -fsSL https://www.geckosweb.cn/install.sh | bash

# Start the service
geckos serve
```

After installation, open the URL shown in your terminal. Default credentials: `admin` / `123456` (please change immediately on first login).

## Use Cases

- Personal server / NAS management
- Cloud server operations
- Embedded devices (Raspberry Pi, etc.)
- Development & testing environments
- Shared team host management

---

Learn more at [www.geckosweb.cn](https://www.geckosweb.cn)
