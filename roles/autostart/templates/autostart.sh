#!/usr/bin/env bash

# Managed by Ansible: start any autostart app that is not running
apps=(
  {% for app in autostart_apps %}
  "{{ app }}"
  {% endfor %}
)

for app in "${apps[@]}"; do
  if pgrep -f "/${app}.app/Contents/MacOS/" >/dev/null; then
    echo "running: $app"
  else
    echo "starting: $app"
    open -g -a "$app"
  fi
done
