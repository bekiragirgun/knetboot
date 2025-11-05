#!/usr/bin/env python3
"""
Kapadokya NetBoot - Menu Generator
Automatically generates iPXE menu files from images.yaml
Version: 1.0
"""

import yaml
from pathlib import Path
from collections import defaultdict

# Paths
BASE_DIR = Path('/opt/knetboot')
CONFIG_DIR = BASE_DIR / 'config'
MENUS_DIR = CONFIG_DIR / 'menus'
IMAGES_YAML = CONFIG_DIR / 'images.yaml'
SETTINGS_YAML = CONFIG_DIR / 'settings.yaml'

def load_yaml(file_path):
    """Load YAML file"""
    with open(file_path) as f:
        return yaml.safe_load(f)

def save_ipxe_file(file_path, content):
    """Save iPXE menu file"""
    with open(file_path, 'w') as f:
        f.write(content)
    print(f"✓ Generated: {file_path.name}")

def generate_main_menu(categories):
    """Generate main.ipxe menu"""
    menu = """#!ipxe

:main_menu
menu Kapadokya NetBoot - Main Menu
item --gap -- Boot Options:
"""

    # Add categories
    for cat_id, cat_name in sorted(categories.items()):
        menu += f"item {cat_id}_menu {cat_name}\n"

    menu += """item --gap -- System:
item local Boot from Local Disk
item shell iPXE Shell
item reboot Reboot
item exit Exit to BIOS
item --gap --
choose --timeout 30000 --default local selected && goto ${selected}

:local
echo Booting from local disk...
exit

:shell
shell

:reboot
reboot

:exit
exit

"""

    # Add category jumps
    for cat_id in categories.keys():
        menu += f":{cat_id}_menu\nchain ${{base_url}}/menus/{cat_id}.ipxe || goto main_menu\n\n"

    return menu

def generate_category_menu(category, images, server_ip):
    """Generate category-specific menu (e.g., ubuntu.ipxe)"""
    cat_id = category['id']
    cat_name = category['name']

    menu = f"""#!ipxe

:{cat_id}_menu
menu {cat_name}
item --gap -- Available Images:
"""

    # Add images
    for img in images:
        status = "[Enabled]" if img.get('enabled', False) else "[Disabled]"
        menu += f"item {img['id']} {img['name']} {status}\n"

    menu += """item --gap --
item back_main Back to Main Menu
choose selected && goto ${selected}

"""

    # Add boot entries for each image
    for img in images:
        if img.get('type') == 'local':
            menu += f":{img['id']}\nexit\n\n"
        elif img.get('kernel'):
            menu += f":{img['id']}\n"
            menu += f"set base_url http://{server_ip}/knetboot\n"

            # Kernel path
            kernel_path = img['kernel'].replace('assets/', '${base_url}/assets/')
            menu += f"kernel {kernel_path}\n"

            # Initrd path (if exists)
            if img.get('initrd'):
                initrd_path = img['initrd'].replace('assets/', '${base_url}/assets/')
                menu += f"initrd {initrd_path}\n"

            # Boot arguments
            if img.get('squashfs'):
                squashfs_path = img['squashfs'].replace('assets/', f'http://{server_ip}/knetboot/assets/')
                boot_args = img.get('boot_args', 'boot=casper netboot=url ip=dhcp')
                menu += f"imgargs vmlinuz {boot_args} url={squashfs_path}\n"
            elif img.get('boot_args'):
                menu += f"imgargs vmlinuz {img['boot_args']}\n"

            menu += f"boot || goto {cat_id}_menu\n\n"

    menu += f":back_main\nchain ${{base_url}}/menus/main.ipxe\n"

    return menu

def main():
    print("=" * 50)
    print("Kapadokya NetBoot - Menu Generator")
    print("=" * 50)

    # Load configurations
    print("\n[1/4] Loading configuration files...")
    images_data = load_yaml(IMAGES_YAML)
    settings_data = load_yaml(SETTINGS_YAML)
    images = images_data.get('images', [])
    server_ip = settings_data.get('server', {}).get('ip', '192.168.27.254')

    print(f"  - Found {len(images)} images")
    print(f"  - Server IP: {server_ip}")

    # Group images by category
    print("\n[2/4] Grouping images by category...")
    categories_dict = defaultdict(list)
    categories_names = {}

    for img in images:
        if not img.get('enabled', False):
            continue  # Skip disabled images

        category = img.get('category', 'other')
        categories_dict[category].append(img)

        # Category display names
        if category not in categories_names:
            category_map = {
                'ubuntu': 'Ubuntu Distributions',
                'debian': 'Debian',
                'centos': 'CentOS / RHEL',
                'fedora': 'Fedora',
                'custom': 'Custom Images',
                'tools': 'Diagnostic Tools',
                'system': 'System',
                'other': 'Other'
            }
            categories_names[category] = category_map.get(category, category.title())

    print(f"  - Categories: {', '.join(categories_dict.keys())}")

    # Create menus directory
    MENUS_DIR.mkdir(parents=True, exist_ok=True)

    # Generate main menu
    print("\n[3/4] Generating main menu...")
    main_menu_content = generate_main_menu(categories_names)
    save_ipxe_file(MENUS_DIR / 'main.ipxe', main_menu_content)

    # Generate category menus
    print("\n[4/4] Generating category menus...")
    for cat_id, cat_images in categories_dict.items():
        category = {
            'id': cat_id,
            'name': categories_names[cat_id]
        }
        menu_content = generate_category_menu(category, cat_images, server_ip)
        save_ipxe_file(MENUS_DIR / f'{cat_id}.ipxe', menu_content)

    print("\n" + "=" * 50)
    print("✓ Menu generation complete!")
    print("=" * 50)
    print(f"\nGenerated files in: {MENUS_DIR}")
    print(f"Boot URL: http://{server_ip}/knetboot/boot.ipxe")

if __name__ == '__main__':
    main()
