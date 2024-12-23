#!/usr/bin/env zsh

# -- PATH -- #
# Move gnu coreutils out of global path; use GNU-prefixed commands instead
export PATH="/opt/homebrew/opt/coreutils/libexec/gnuman:$PATH"

# binutils
export PATH="/opt/homebrew/opt/binutils/bin:$PATH"

# gnu grep
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"

# gnu sed
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

# gnu awk
export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"

# gnu tar
export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"

# llvm / clang
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# pyenv
export PATH="$PYENV_ROOT/bin:$PATH" # add pyenv to path

# zip
export PATH="/opt/homebrew/opt/zip/bin:$PATH"

# gcc
export PATH="/opt/homebrew/opt/gcc:$PATH"

# unzip
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"

# ansible-lint
# export PATH="$(/bin/ls -d /opt/homebrew/Cellar/ansible-lint/*/ | sort -V | tail -n 1)libexec/bin:$PATH"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
