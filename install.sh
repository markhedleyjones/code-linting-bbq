#!/usr/bin/env bash

set -eo pipefail

script_path="$(dirname "$(realpath $0)")"
image_name="code-linting-bbq"

# Check that an image with the 'latest' tag exists for the image_name
if ! docker image inspect ${image_name}:latest >/dev/null 2>&1; then
	echo "Image ${image_name}:latest does not exist in Docker"
	echo "Run 'make production' to build the image"
	exit 1
fi

# Check that docker-bbq is installed
if ! command -v run >/dev/null 2>&1 || ! command -v bbq-create >/dev/null 2>&1; then
	echo "docker-bbq is not installed"
	echo "Please install docker-bbq from https://github.com/MarkHedleyJones/docker-bbq"
	exit 1
fi

linting_scripts=$(find ${script_path}/install/* -maxdepth 0 -type f -perm -u+x | xargs -I{} basename {})

echo "This script will link the following linters into your local bin directory:"
for script in ${linting_scripts[@]}; do
	echo " - ${script}"
done

# Get user confirmation
read -p "Do you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "Aborting"
	exit 1
fi

mkdir -p ${HOME}/.local/bin
for script in ${linting_scripts[@]}; do
	echo "Linking ${script}"
	script_path=${HOME}/.local/bin/${script}
	cat >${script_path} <<EOF
#!/usr/bin/env bash

# Collect all arguments as paths/files to check
paths_to_check=()
scan_directory=""

# Process arguments
if [ \$# -eq 0 ]; then
    # No arguments, scan current directory
    scan_directory=\$(pwd)
    paths_to_check=(".")
else
    # Process each argument to find the common base directory
    for arg in "\$@"; do
        if [ -f "\$arg" ]; then
            # It's a file
            realpath_arg=\$(realpath "\$arg")
            paths_to_check+=("\$realpath_arg")
        elif [ -d "\$arg" ]; then
            # It's a directory
            realpath_arg=\$(realpath "\$arg")
            paths_to_check+=("\$realpath_arg")
        else
            echo "Warning: '\$arg' is neither a file nor a directory, skipping"
        fi
    done
    
    # Find the common base directory for all paths
    if [ \${#paths_to_check[@]} -gt 0 ]; then
        # Get the common parent directory
        scan_directory=\$(dirname "\${paths_to_check[0]}")
        for path in "\${paths_to_check[@]}"; do
            while [[ ! "\$path" =~ ^\$scan_directory ]]; do
                scan_directory=\$(dirname "\$scan_directory")
            done
        done
    else
        echo "Error: No valid files or directories provided"
        exit 1
    fi
fi

echo "Base directory: \${scan_directory}"

# Convert absolute paths to relative paths from scan_directory
relative_paths=()
for path in "\${paths_to_check[@]}"; do
    if [ "\$path" = "." ]; then
        relative_paths+=(".")
    else
        relative_path=\${path#\$scan_directory/}
        relative_paths+=("\$relative_path")
    fi
done

path_output=/tmp/code-linting-bbq
if [ -d \${path_output} ]; then
    rm -rf \${path_output}
fi
mkdir -p /tmp/code-linting-bbq

# Pass the relative paths as arguments to the linter inside the container
run --image code-linting-bbq --mount \${scan_directory} --mount-output \${path_output} ${script} "\${relative_paths[@]}"
EOF
	chmod +x ${script_path}
done

echo "Done, you can now run the linters from any directory"
