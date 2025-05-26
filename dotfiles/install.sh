#!/usr/bin/env python3
import os
import shutil
import subprocess
import platform
from pathlib import Path

# Конфиги и пути
CONFIG_DIR = Path.home() / ".config"
BACKUP_DIR = Path.home() / ".config_backup"
SOURCE_DIR = Path("dotfiles")

# Зависимости для разных дистрибутивов
DEPS = {
    "arch": [
        "polybar", "i3-wm", "ulauncher", "picom", "feh", "zenity",
        "python-nautilus", "libkeybinder3", "flameshot", 
        "nerd-fonts-jetbrains-mono"
    ],
    "debian": [
        "polybar", "i3", "ulauncher", "picom", "feh", "zenity",
        "python3-nautilus", "libkeybinder-3.0-0", "flameshot",
        "fonts-jetbrains-mono"
    ],
    "fedora": [
        "polybar", "i3", "ulauncher", "picom", "feh", "zenity",
        "python3-nautilus", "keybinder3", "flameshot",
        "jetbrains-mono-fonts"
    ]
}

def get_distro():
    """Определение дистрибутива с помощью os-release"""
    try:
        with open("/etc/os-release") as f:
            content = f.read().lower()
            if "arch" in content or "endeavouros" in content:
                return "arch"
            elif "debian" in content or "ubuntu" in content:
                return "debian"
            elif "fedora" in content:
                return "fedora"
    except FileNotFoundError:
        pass

    if shutil.which("apt-get"):
        return "debian"
    elif shutil.which("dnf"):
        return "fedora"
    return "unknown"

def install_deps(distro):
    """Установка зависимостей для выбранного дистрибутива"""
    print(f"🔄 Установка зависимостей для {distro}...")
    
    if distro == "arch":
        # Установка yay если отсутствует
        if not shutil.which("yay"):
            subprocess.run(["sudo", "pacman", "-S", "--noconfirm", "git", "base-devel"])
            subprocess.run(["git", "clone", "https://aur.archlinux.org/yay.git"])
            os.chdir("yay")
            subprocess.run(["makepkg", "-si", "--noconfirm"])
            os.chdir("..")
            shutil.rmtree("yay")
        
        subprocess.run(["yay", "-S", "--noconfirm"] + DEPS["arch"])
    
    elif distro == "debian":
        subprocess.run(["sudo", "apt-get", "update"])
        subprocess.run(["sudo", "apt-get", "install", "-y"] + DEPS["debian"])
    
    elif distro == "fedora":
        subprocess.run(["sudo", "dnf", "install", "-y"] + DEPS["fedora"])
    
    else:
        print("❌ Неподдерживаемый дистрибутив!")
        exit(1)

def backup_configs():
    """Создание бэкапа конфигов"""
    print("📦 Создание бэкапа...")
    BACKUP_DIR.mkdir(exist_ok=True)
    
    for item in CONFIG_DIR.iterdir():
        if item.name in ["i3", "polybar", "picom.conf", "ulauncher"]:
            target = BACKUP_DIR / item.name
            if target.exists():
                shutil.rmtree(target) if target.is_dir() else target.unlink()
            shutil.move(str(item), str(target))

def deploy_configs():
    """Копирование новых конфигов"""
    print("🚀 Установка конфигов...")
    
    # Основные конфиги
    shutil.copytree(SOURCE_DIR / "i3", CONFIG_DIR / "i3", dirs_exist_ok=True)
    shutil.copytree(SOURCE_DIR / "polybar", CONFIG_DIR / "polybar", dirs_exist_ok=True)
    
    # Установка прав для скриптов
    scripts = [
        CONFIG_DIR / "i3" / "power-menu.sh",
        CONFIG_DIR / "i3" / "ulauncher-toggle.sh"
    ]
    for script in scripts:
        script.chmod(0o755)

def main():
    if os.geteuid() == 0:
        print("❌ Не запускай скрипт от root!")
        exit(1)
    
    if not SOURCE_DIR.exists():
        print(f"❌ Папка {SOURCE_DIR} не найдена!")
        exit(1)
    
    distro = get_distro()
    if distro == "unknown":
        print("❌ Дистрибутив не распознан!")
        exit(1)
    
    install_deps(distro)
    backup_configs()
    deploy_configs()
    
    print("\n✅ Готово!")

if __name__ == "__main__":
    main()