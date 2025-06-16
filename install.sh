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
    cat > ${script_path} << 'EOF'
#!/usr/bin/env bash

scan_directory=$(pwd)
if [ -n "$1" ]; then
    if [ ! -d "$1" ]; then
        echo "Error: The provided path '$1' is not a directory."
        exit 1
    fi
    scan_directory=$(realpath $1)
fi

echo "Scanning: ${scan_directory}"

path_output=/tmp/code-linting-bbq
if [ -d ${path_output} ]; then
    rm -rf ${path_output}
fi
mkdir -p /tmp/code-linting-bbq
run --image code-linting-bbq --mount ${scan_directory} --mount-output ${path_output} lint-sq
EOF
    chmod +x ${script_path}
done

echo "Done, you can now run the linters from any directory"
