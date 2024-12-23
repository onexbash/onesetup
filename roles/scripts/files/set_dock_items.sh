#!/bin/bash
LOGGED_USER=$(/usr/bin/stat -f%Su /dev/console)
sudo su "$LOGGED_USER" -c 'defaults delete com.apple.dock persistent-apps'

dock_item() {

  printf '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>', "$1"

}

firefox=$(dock_item '/Applications/Firefox Developer Edition.app')
alacritty=$(dock_item '/Applications/Alacritty.app')
chatgpt=$(dock_item '/Applications/ChatGPT.app')
outline=$(dock_item '/Applications/Outline.app')
discord=$(dock_item '/Applications/Discord.app')
spotify=$(dock_item '/Applications/Spotify.app')
proton_mail=$(dock_item '/Applications/Proton Mail.app')
proton_drive=$(dock_item '/Applications/Proton Drive.app')
proton_vpn=$(dock_item '/Applications/ProtonVPN.app')
authenticator=$(dock_item '/Applications/Authenticator.app')
ms_outlook=$(dock_item '/Applications/Microsoft Outlook.app')
ms_teams=$(dock_item '/Applications/Microsoft Teams.app')
keepassxc=$(dock_item '/Applications/KeePassXC.app')
sublime=$(dock_item '/Applications/Sublime Text.app')
docker=$(dock_item '/Applications/Docker.app')
messages=$(dock_item '/System/Applications/Messages.app')

sudo su "$LOGGED_USER" -c "defaults write com.apple.dock persistent-apps -array '$firefox' '$alacritty' '$chatgpt' '$outline' '$discord' '$spotify' '$proton_mail' '$authenticator' '$ms_outlook' '$ms_teams' '$keepassxc' '$sublime' '$docker' '$messages' "
killall Dock
