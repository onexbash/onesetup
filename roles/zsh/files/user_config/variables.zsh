#!/usr/bin/env zsh

# -- HEX COLOR CODES -- #
# catppuccin mocha
export ROSEWATER=""
export PINK="#f5c2e7"
export MAUVE="#cba6f7"
export RED="#f38ba8"
export MAROON="#eba0ac"
export PEACH="#fab387"
export YELLOW="#f9e2af"
export GREEN="#a6e3a1"
export TEAL="#94e2d5"
export BLUE="#89b4fa"
export LAVENDER="#b4befe"

# -- TERMINAL COLORS -- #
export C_BLACK='\033[1;30m'
export C_RED='\033[1;31m'
export C_GREEN='\033[1;32m'
export C_YELLOW='\033[1;33m'
export C_BLUE='\033[1;34m'
export C_PURPLE='\033[1;35m'
export C_CYAN='\033[1;36m'
export C_WHITE='\033[1;37m'
export C_GRAY='\033[1;34m'
export C_RESET='\033[0m'


# -- INFO PROMPTS -- #
export I_SKIP="${C_BLACK}[${C_CYAN} SKIPPING ${C_BLACK}] ${C_RESET}" # skipping
export I_WARN="${C_BLACK}[${C_YELLOW} WARNING ${C_BLACK}] ${C_RESET}" # warning
export I_OK="${C_BLACK}[${C_GREEN}  OK  ${C_BLACK}] ${C_RESET}" # ok
export I_INFO="${C_BLACK}[${C_PURPLE} INFO ${C_BLACK}] ${C_RESET}" # info
export I_ERR="${C_BLACK}[${C_YELLOW} ERROR ${C_BLACK}] ${C_RESET}" # error
export I_YN="${C_BLACK}[${C_BLUE} y/n ${C_BLACK}] ${C_RESET}" # ask user for yes/no
export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}" # ask user for anything
export I_LOAD="${C_BLACK}[${C_BLUE} LOADING .. ${C_BLACK}] ${C_RESET}" # ask user for anything

# -- DIRECTORY VARIABLES -- #
export RECYBA="$DEV/projects/cratos/recyba"
