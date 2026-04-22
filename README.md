# 🔐 Secure Web Server Automation (Nginx + SSL + GUI)

An advanced Bash automation tool for provisioning a secure Nginx web server with HTTPS, logging, and GUI-driven configuration. Designed to simulate real-world DevOps workflows with a focus on security, reliability, and usability.

---

## 📌 Overview

This project automates the complete lifecycle of deploying a secure web server environment. It integrates:

* Web server provisioning
* SSL/TLS encryption
* Virtual host configuration
* Logging and monitoring
* GUI-based user interaction

Built as part of an OS course project, but structured to reflect **industry-grade server automation practices**.

---

## 🧩 Architecture

```
User (Zenity GUI)
        │
        ▼
Authentication Layer (Basic Login)
        │
        ▼
Provisioning Engine (Bash Script)
        │
 ┌──────┼────────┬─────────────┐
 ▼      ▼        ▼             ▼
Nginx  SSL   File System   Logging System
Setup  Cert   Structure     (Access/Error)
```

---

## ⚡ Key Capabilities

### 🔧 Automated Provisioning

* Installs and configures Nginx from scratch
* Handles service enable/start/restart lifecycle
* Fixes broken Nginx include paths automatically

### 🔐 Security Layer

* Generates **self-signed SSL certificates (RSA 2048-bit)**
* Enforces **TLS v1.2 and v1.3 only**
* Configures secure cipher suites
* Implements HTTP → HTTPS redirection

### 🌐 Virtual Host Management

* Dynamic domain-based configuration
* Auto-creation of:

  * `/var/www/<domain>/public`
  * Nginx server blocks
* Removes default site conflicts

### 📊 Observability & Logging

* Dedicated access and error logs per domain
* Real-time log preview via GUI
* Automatic log generation using `curl`

### 🖥️ GUI-Based Workflow

* Built with **Zenity**
* Provides:

  * Setup wizard
  * Login authentication
  * Progress tracking
  * Error reporting
  * Log viewer

---

## 🔐 Authentication

Basic login system implemented:

| Username | Password |
| -------- | -------- |
| admin    | 1234     |

> ⚠️ Hardcoded credentials are used for demonstration. Replace with secure authentication in production.

---

## 📂 File System Layout

```
/var/www/<domain>/public        → Website root
/etc/nginx/ssl/                → SSL certificates
/etc/nginx/sites-available/    → Config files
/etc/nginx/sites-enabled/      → Active sites
/var/log/nginx/                → Logs
```

---

## 🚀 Deployment Guide

### 1. Clone Repository

```bash
git clone https://github.com/your-username/secure-web-server.git
cd secure-web-server
```

### 2. Set Permissions

```bash
chmod +x webserver_setup.sh
```

### 3. Execute Script

```bash
sudo bash webserver_setup.sh
```

---

## 🔄 Workflow Execution

1. Root privilege validation
2. Dependency installation
3. User authentication via GUI
4. Domain input and validation
5. Directory and HTML template generation
6. SSL certificate creation
7. Nginx configuration generation
8. Configuration validation (`nginx -t`)
9. Service restart and activation
10. Log generation and visualization

---

## 🛡️ Security Considerations

* Self-signed certificates are not trusted by browsers
* No firewall rules applied (e.g., UFW not configured)
* Credentials stored in plaintext
* No rate limiting or intrusion detection

---

## 📈 Potential Enhancements

### 🔒 Security Upgrades

* Integrate **Let’s Encrypt (Certbot)**
* Add **fail2ban** for intrusion prevention
* Implement secure credential storage (hashed)

### ⚙️ DevOps Extensions

* Docker containerization
* CI/CD pipeline integration
* Multi-domain and subdomain support

### 📊 Monitoring

* Integrate Prometheus + Grafana
* Real-time log streaming dashboard

---

## 🧪 Testing & Validation

* Nginx configuration tested using:

```bash
nginx -t
```

* HTTPS endpoint verified via:

```bash
curl -k https://your-domain
```

---

## 📷 Demo Output

After successful execution:

* ✅ HTTPS enabled site
* ✅ Styled default landing page
* ✅ Logs generated and viewable
* ✅ Fully functional Nginx server

---

## 📘 Academic Context

* Course: Operating Systems
* Focus: Process automation, system configuration, Linux administration

---

## 👨‍💻 Author

**Sunjid Ahmed Siyem**
CSE Student | Cybersecurity Enthusiast

---

## 📄 License

This project is for educational purposes. You may modify and reuse with attribution.

---
