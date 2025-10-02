import sys
import os

def upsert_option(file_path, option, value):
    """
    Updates or inserts a key-value pair in a text file.

    Args:
        file_path (str): The path to the text file.
        option (str): The key (option) to upsert.
        value (str): The value to set for the option.
    """
    lines = []
    option_found = False

    # Ensure the directory exists
    dir_name = os.path.dirname(file_path)
    if dir_name:
        os.makedirs(dir_name, exist_ok=True)

    # Read the existing file if it exists
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        pass  # File doesn't exist yet, it will be created.

    # Process lines to find and update the option
    new_lines = []
    for line in lines:
        # Check if the line contains the option we are looking for
        if line.strip().startswith(option + ' ='):
            new_lines.append(f"{option} = {value}\n")
            option_found = True
        else:
            new_lines.append(line)

    # If the option was not found, add it to the end
    if not option_found:
        new_lines.append(f"{option} = {value}\n")

    # Write the updated content back to the file
    with open(file_path, 'w') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: python {sys.argv[0]} <file_path> <option> <value>")
        sys.exit(1)

    file_path_arg = sys.argv[1]
    option_arg = sys.argv[2]
    value_arg = sys.argv[3]

    upsert_option(file_path_arg, option_arg, value_arg)
