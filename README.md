# code-linting-bbq

## Dependencies
This project requires [docker-bbq](https://github.com/markhedleyjones/docker-bbq)
Please install it before proceeding.

## Installing
To build the image and install the runner scripts into the local `bin` directory, run:

    make install

## Usage

To lint the current directory using all included linters, run:

    code-lint

To lint a specific file or directory, execute:

    code-lint <file-or-directory>

To run a specific linter, execute:

    code-lint-<linter>

where `<linter>` is one of the scripts under the `install` directory.
