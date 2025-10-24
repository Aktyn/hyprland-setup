import sys
import os
import fcntl
import time
from contextlib import contextmanager

@contextmanager
def file_lock(file_path, timeout=30, retry_interval=0.1):
    """
    Context manager for exclusive file locking.
    
    Args:
        file_path (str): Path to the file to lock
        timeout (float): Maximum time to wait for lock (seconds)
        retry_interval (float): Time between lock attempts (seconds)
    
    Raises:
        TimeoutError: If lock cannot be acquired within timeout
    """
    lock_file_path = file_path + '.lock'
    
    # Create lock file
    try:
        lock_fd = os.open(lock_file_path, os.O_CREAT | os.O_WRONLY | os.O_TRUNC, 0o644)
    except OSError as e:
        raise OSError(f"Failed to create lock file: {e}")
    
    try:
        # Try to acquire exclusive lock with timeout
        start_time = time.time()
        while True:
            try:
                fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break  # Lock acquired
            except BlockingIOError:
                # Lock is held by another process
                if time.time() - start_time > timeout:
                    os.close(lock_fd)
                    raise TimeoutError(f"Could not acquire lock on {file_path} within {timeout} seconds")
                time.sleep(retry_interval)
        
        yield  # Lock is held, execute the protected code
        
    finally:
        # Release lock and clean up
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            os.close(lock_fd)
            os.unlink(lock_file_path)
        except (OSError, IOError):
            # Ignore cleanup errors
            pass

def upsert_option(file_path, option, value):
    """
    Updates or inserts a key-value pair in a text file with thread-safe locking.

    Args:
        file_path (str): The path to the text file.
        option (str): The key (option) to upsert.
        value (str): The value to set for the option.
    
    Raises:
        TimeoutError: If file lock cannot be acquired within timeout period
        OSError: If there are file system related errors
    """
    try:
        with file_lock(file_path):
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
                
    except TimeoutError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"File system error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: python {sys.argv[0]} <file_path> <option> <value>")
        sys.exit(1)

    file_path_arg = sys.argv[1]
    option_arg = sys.argv[2]
    value_arg = sys.argv[3]

    upsert_option(file_path_arg, option_arg, value_arg)
