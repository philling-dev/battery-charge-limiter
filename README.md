# 🔋 Battery Charge Limiter for Linux

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.kernel.org/)

A simple and effective utility to limit the battery charging on your Linux laptop, helping to extend battery lifespan and health.

## ✨ Features

- **Extends Battery Lifespan:** Prevents the battery from being constantly charged to 100%, which can degrade it over time.
- **Easy to Use:** Simple command-line installation and configuration.
- **Persistent:** The charge limit is automatically applied at system startup via `systemd`.
- **Broad Compatibility:** Designed to work with most laptops that expose charge control via `sysfs` (including many ASUS, Lenovo, and Dell models).

## 🚀 Installation

To install the Battery Charge Limiter, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/philling-dev/battery-charge-limiter.git # (This will be your repository)
    cd battery-charge-limiter
    chmod +x install.sh
    ```

2.  **Execute the installation script:**
    ```bash
    sudo ./install.sh
    ```

    The script will:
    - Copy necessary files to `/usr/local/bin/` and `/etc/systemd/system/`.
    - Create a default configuration file in `/etc/bcl.conf` with a 80% charge limit.
    - Enable and start the `bcl.service` to apply the limit at boot.

## 📖 Usage

After installation, the default charge limit is **80%**.

### Change the Charge Limit

To change the charge limit, you need to edit the configuration file and restart the service:

1.  **Edit the configuration file:**
    ```bash
    sudo nano /etc/bcl.conf
    ```
    Change the number to your desired percentage (e.g., `60`, `70`, `90`). Save and close the file.

2.  **Restart the service to apply the change:**
    ```bash
    sudo systemctl restart bcl.service
    ```

### Check Service Status

To check if the service is active and what limit is being applied:

```bash
sudo systemctl status bcl.service
```

### Apply the Limit Immediately (without restarting)

If you have just changed `/etc/bcl.conf` and want to apply the limit without restarting the service or the system:

```bash
sudo bcl-apply
```

## 🗑️ Uninstallation

To remove the Battery Charge Limiter from your system:

```bash
sudo ./uninstall.sh
```

## 💻 Compatibility

This utility attempts to automatically detect the battery charge control file on your system. It looks for common paths like `/sys/class/power_supply/BAT*/charge_control_end_threshold` and `charge_stop_threshold`.

**Your laptop needs to expose this functionality via `sysfs` for this utility to work.** Many modern ASUS, Lenovo, and Dell laptops support this. If the utility does not work, your hardware might not be compatible or might use a different path.

## 🤝 Contributing

Contributions are welcome! If you found a bug, have a suggestion for improvement, or want to add support for new hardware, please open an issue or submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💖 Support the Project

If this project was helpful to you, please consider supporting its development:

### ☕ Buy me a coffee
- **[coff.ee/philling](https://coff.ee/philling)**

### 🪙 Bitcoin
To donate, copy the address below:
```
1Lyy8GJignLbTUoTkR1HKSe8VTkzAvBMLm
```

**Keywords:** `linux`, `battery`, `charge limit`, `threshold`, `laptop`, `asus`, `lenovo`, `dell`, `sysfs`, `systemd`, `power management`, `battery health`, `lifespan`, `conservation mode`

**Keywords:** `linux`, `battery`, `charge limit`, `threshold`, `laptop`, `asus`, `lenovo`, `dell`, `sysfs`, `systemd`, `power management`, `battery health`, `lifespan`, `conservation mode`
