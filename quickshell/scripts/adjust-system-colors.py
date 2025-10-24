
import json
import sys
import os

def hex_to_rgba(hex_color, alpha=1.0):
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return f'rgba({r},{g},{b},{alpha})'

def hex_to_rgb_string(hex_color):
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return f'{r},{g},{b}'


def update_gtk_styles(colors):
    gtk3_css_path = f"{os.path.expanduser("~")}/.config/gtk-3.0/gtk.css"
    gtk4_css_path = f"{os.path.expanduser("~")}/.config/gtk-4.0/gtk.css"

    # Read GTK-3.0 template
    try:
        with open('templates/gtk-3.0-template.css', 'r') as f:
            gtk3_template = f.read()
    except FileNotFoundError:
        print("Error: gtk-3.0-template.css not found in the script directory.")
        return

    # Read GTK-4.0 template
    try:
        with open('templates/gtk-4.0-template.css', 'r') as f:
            gtk4_template = f.read()
    except FileNotFoundError:
        print("Error: gtk-4.0-template.css not found in the script directory.")
        return

    # Replace placeholders
    gtk3_css = gtk3_template
    gtk4_css = gtk4_template
    for color_name, color_value in colors.items():
        # CSS variables are case-sensitive, so we need to be careful here.
        # The keys in colors.json are camelCase, but the placeholders in the templates are {camelCase}.
        placeholder = f"{{{color_name}}}"
        gtk3_css = gtk3_css.replace(placeholder, color_value)
        gtk4_css = gtk4_css.replace(placeholder, color_value)

    # Override stylesheets
    try:
        with open(gtk3_css_path, 'w') as f:
            f.write(gtk3_css)

        with open(gtk4_css_path, 'w') as f:
            f.write(gtk4_css)
    except Exception as e:
        print(f"Error while overriding gtk stylesheets: {e}")
        return

    print("GTK stylesheets updated successfully.")

def update_kitty_styles(colors):
    kitty_conf_path = f"{os.path.expanduser("~")}/.config/kitty/kitty.conf"

    try:
        with open('templates/kitty-template.conf', 'r') as f:
            kitty_template = f.read()
    except FileNotFoundError:
        print("Error: kitty-template.conf not found in the script directory.")
        return

    kitty_conf = kitty_template
    for color_name, color_value in colors.items():
        placeholder = f"{{{color_name}}}"
        kitty_conf = kitty_conf.replace(placeholder, color_value)

    try:
        if os.path.exists(kitty_conf_path):
            with open(kitty_conf_path, 'r') as f:
                existing_kitty_conf = f.read()
        else:
            existing_kitty_conf = ""

        start_marker = "# BEGIN: QuickShell-managed colors"
        end_marker = "# END: QuickShell-managed colors"

        if start_marker in existing_kitty_conf:
            start_index = existing_kitty_conf.find(start_marker)
            end_index = existing_kitty_conf.find(end_marker) + len(end_marker)
            new_kitty_conf = existing_kitty_conf[:start_index] + kitty_conf + existing_kitty_conf[end_index:]
        else:
            new_kitty_conf = existing_kitty_conf + "\n" + kitty_conf

        with open(kitty_conf_path, 'w') as f:
            f.write(new_kitty_conf)

        print("Kitty terminal colors updated successfully.")
    except Exception as e:
        print(f"Error while updating kitty configuration: {e}")
        return

def update_kde_colors(colors):
    colorscheme_path = f"{os.path.expanduser('~')}/.local/share/color-schemes/MaterialYou.colors"
    default_colorscheme_path = "defaults/MaterialYou.colors"

    try:
        with open('templates/kdeglobals-template', 'r') as f:
            kdeglobals_template_content = f.read()
    except FileNotFoundError:
        print("Error: kdeglobals-template not found in the script directory.")
        return

    # Prepare replacements from the template
    replacements = {}
    current_section = None
    for line in kdeglobals_template_content.splitlines():
        line = line.strip()
        if line.startswith('[') and line.endswith(']'):
            current_section = line
        elif '=' in line and current_section:
            key, value_placeholder = line.split('=', 1)
            for color_name, hex_color_value in colors.items():
                placeholder = f"{{{color_name}}}"
                if placeholder in value_placeholder:
                    replacements[f'{current_section}{key}'] = f'{key}={hex_to_rgb_string(hex_color_value)}'
                    break

    try:
        with open(default_colorscheme_path, 'r') as f:
            kdeglobals_content = f.readlines()
    except FileNotFoundError:
        print(f"Error: {default_colorscheme_path} not found.")
        return

    new_kdeglobals_content = []
    current_section = None
    for line in kdeglobals_content:
        stripped_line = line.strip()
        if stripped_line.startswith('[') and stripped_line.endswith(']'):
            current_section = stripped_line
            new_kdeglobals_content.append(line)
        elif '=' in stripped_line and current_section:
            key, _ = stripped_line.split('=', 1)
            replacement_key = f'{current_section}{key}'
            if replacement_key in replacements:
                new_kdeglobals_content.append(replacements[replacement_key] + '\n')
            else:
                new_kdeglobals_content.append(line)
        else:
            new_kdeglobals_content.append(line)

    try:
        with open(colorscheme_path, 'w') as f:
            f.writelines(new_kdeglobals_content)

        # Applying color scheme
        try:
            print(f"Applying scheme: {os.path.basename(colorscheme_path)}")
            # TODO: find better solution to reapply already used theme
            os.system(f"plasma-apply-colorscheme BreezeDark && sleep 1 && plasma-apply-colorscheme MaterialYou")
        except Exception as e:
            print(f"Error while applying plasma color scheme: {e}")

        print("KDE colors updated successfully.")
    except Exception as e:
        print(f"Error while updating KDE configuration: {e}")
        return

def main():
    if len(sys.argv) != 2:
        print("Usage: python adjust-system-colors.py <path_to_colors.json>")
        sys.exit(1)

    colors_json_path = sys.argv[1]

    try:
        with open(colors_json_path, 'r') as f:
            colors_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: colors.json file not found at {colors_json_path}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from {colors_json_path}")
        sys.exit(1)

    colors = colors_data.get('colors', {})
    if not colors:
        print("Error: 'colors' key not found in colors.json")
        sys.exit(1)

    update_gtk_styles(colors)
    update_kitty_styles(colors)
    update_kde_colors(colors)

if __name__ == "__main__":
    main()
