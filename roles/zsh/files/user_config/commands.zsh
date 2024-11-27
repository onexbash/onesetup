#!/usr/bin/env zsh


# remove an app from gatekeeper quarantine
function remove_from_quarantine() {
  xattr -rd com.apple.quarantine "/Applications/${app_name}.app"
}
