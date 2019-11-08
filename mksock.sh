#!/bin/bash

appdata="$(cmd.exe /C set APPDATA | tr -d '\r\n' | cut -d= -f2- | tr '\\' '/' 2>/dev/null)"

sudo tee /etc/systemd/system/wsl-glue.servce <<EOF
[Unit]
Description=User Session
Requires=user@$(id -u).service

[Service]
User=$USER
Group=$(id -gn)
ExecStart=/bin/bash -c 'while true; do sleep 300; done'

[Install]
WantedBy=basic.target

EOF



if [ -z "$appdata" ]; then
  echo "Unable to find AppData"
  exit 1
fi

sockets="X0 gpg-agent gpg-agent.browser gpg-agent.extra gpg-agent.ssh scdaemon uiserver dirmngr"
for s in $sockets; do
    unit="$(echo $s|tr '.' '-')"
    systemctl --user disable --now ${unit}.socket

    pipeargs="-ei -ep -a"
    pipe="$appdata/gnupg/S.${s}"
    socket="%t/gnupg/S.${s}"

    if [ "$s" == "X0" ]; then
        socket="/tmp/.X11-unix/X0"
        pipeargs="-s -ei -ep -nt"
        pipe="6000"
    fi
    if [ "$s" == "gpg-agent.ssh" ]; then
        pipeargs="-ei -ep"
        pipe="//./pipe/ssh"
    fi

    sudo tee /etc/systemd/user/${unit}.socket <<EOF
[Socket]
ListenStream=${socket}
SocketMode=0600
DirectoryMode=0700
Accept=yes

[Install]
WantedBy=sockets.target
EOF
    sudo tee /etc/systemd/user/${unit}@.service <<EOF
[Service]
EnvironmentFile=/etc/default/wsl
ExecStart=/mnt/c/npiperelay.exe ${pipeargs} ${pipe}
StandardInput=socket
EOF

done

sudo systemctl daemon-reload
sudo systemctl enable --now wsl-glue.service
systemctl --user daemon-reload

for s in $sockets; do
    unit="$(echo $s|tr '.' '-')"
    systemctl --user enable --now ${unit}.socket
done
