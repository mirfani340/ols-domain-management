# OLS Domain Management Script

Enhanced OpenLiteSpeed (OLS) domain provisioning & SSL automation script with an interactive CLI dashboard, per‑domain logging, graceful reloads, and optional automatic SSL vHost enablement.

Originally based on xpressos/OLSSCRIPTS-olsdomain (GPLv3). Modernized and extended by `irfani.dev` (2025).

## ✨ Features

- Interactive dashboard (no arguments needed)
- Add / remove virtual hosts quickly
- Automatic directory scaffolding (conf, logs, web root)
- Per-domain access log: `/usr/local/lsws/logs/<domain>/access.log`
- Custom combined log format (includes Referer & User-Agent)
- Let's Encrypt SSL issuance via Certbot (webroot method)
- Optional immediate SSL enable (adds `vhssl` block + 443 listener map)
- Graceful reload (`lswsctrl reload`) fallback to restart
- Multi-distro detection (CentOS, AlmaLinux, Rocky, Ubuntu, Debian)

## 🚀 Quick Start (Interactive Mode)

```
./olsdomain.sh
```

### Menu Options
1. Add new domain
   - Prompts: domain, site root (default `/usr/local/lsws/www/<domain>`)
   - Creates: `conf/vhosts/<domain>`, `logs/<domain>`, `www/<domain>`
   - Generates minimal `index.html`
   - Writes vHost + mapping to `httpd_config.conf`
   - Gracefully reloads OLS

2. Remove domain
   - Removes mapping + `virtualhost` block
   - Deletes vHost config directory
   - Optionally deletes logs + web root
   - Restarts OLS

3. Install SSL On Domain
   - Prompts: domain, email, optional webroot
   - Runs: `certbot certonly --webroot -w <webroot> -d <domain> -m <email> --agree-tos -n -v`
   - Prompts to enable SSL (adds `vhssl` block + ensures 443 listener `map`)
   - Gracefully reloads OLS if enabled

4. Exit

## 🔧 Non-Interactive (Legacy Flags)

```
./olsdomain.sh -d example.com -e admin@example.com -p /usr/local/lsws/www/example.com
```
This will:
1. Create site structure (if missing)
2. Configure vHost & mapping
3. Issue SSL (webroot)
4. Attempt to enable SSL automatically
5. Run a basic test fetch

## 📁 Directory Layout

```
/usr/local/lsws/www/<domain>         # Web root (vhRoot/docRoot)
/usr/local/lsws/logs/<domain>/access.log  # Per-domain access log
/usr/local/lsws/conf/vhosts/<domain>/vhconf.conf  # vHost config
```

## 📝 Access Log Format

Configured inside each new vHost:
```
%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-Agent}i"
```

## 🔒 SSL Enable Mechanics

After certificate issuance you can enable SSL immediately (interactive) or it will auto-attempt in non-interactive mode. This inserts:
- A `vhssl { ... }` block into: `/usr/local/lsws/conf/vhosts/<domain>/vhconf.conf`
- A 443 listener (if missing) or adds a `map <domain> <domain>` line to an existing one.

Certificates are expected at:
```
/etc/letsencrypt/live/<domain>/fullchain.pem
/etc/letsencrypt/live/<domain>/privkey.pem
```

If you need to re-run SSL enable manually:
```
fn_enable_ssl_vhost <domain>
```
(Run from within the script context / sourced environment.)

## 🛠 Manual Certbot Example

```
certbot certonly --webroot -w /usr/local/lsws/www/example.com -d example.com -m you@example.com --agree-tos -n -v
```

Then enable SSL (if not already):
```
./olsdomain.sh   # choose Install SSL On Domain, or run enable function
```

## 🧪 Health Test

After deployment the script performs a simple HTTP fetch for the keyword "Congratulation". Adjust `fn_test_site` as needed for your content.

## 🐛 Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| certbot not found | Package missing | Let script auto-install or `apt/yum install certbot` |
| SSL enable says cert files missing | Cert issuance failed | Re-run Install SSL and check DNS / firewall |
| Reload fails | Older OLS version | Falls back to restart automatically |
| 443 not serving domain | Missing map line | Re-run SSL enable or manually add map in listener |

## 🧾 License
GPL v3 or later. See `LICENSE`.

## ✅ Supported / Detected Distros
CentOS (6–9), AlmaLinux (8/9), Rocky (8/9), Ubuntu (14/16/18), Debian (7–9). Newer versions likely compatible but not fully tested.

## Tested
Centos 7 🐧

Almalinux 9 🐧

## 🙌 Credits
Original: Xpressos CDC
Modern enhancements: irfani.dev (2025)

Contributions / PRs welcome.
