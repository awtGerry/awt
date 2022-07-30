#!/bin/sh

echo -e "Instalador de dotfiles y programas para arch/artix linux"
echo -e "## Para que el instalador funcione por completo tiene que ser ejecutado con permisos de root ##"

dotfiles="https://github.com/awtGerry/.dotfiles"
programas="https://raw.githubusercontent.com/awtGerry/awt/master/programas.csv"

# Usuario ingresa nombre y contrasena
# TODO: implementar esto para que sea desde una instalacion en blanco de arch.
echo -e "> Ingrese nombre de usuario: \c"
read user
echo -e "> Ingrese contraseña [sudo] de $user: \c"
read -s pass
echo ""
sudo -u "$user" mkdir -p "/home/$user/.cache/zsh"
sudo -u "$user" mkdir -p "/home/$user/.cache/nvim/undodir"

# add_user_pass() { # pregunta si el usuario quiere agregar user y pass (para instalacion en blanco)
# }

salir() { # si hay un error salir recibiendo un mensaje de donde surgio el error
          # NOTE: prob temporal solo para ver en donde puede haber errores
    printf "%s\n" "$1" >&2;
    exit 1;
}

# Funciones de instaladores de programas (git,pacman,yay)
ask_default_install() { # programas necesarios
    while true; do
        read -p "> Desea instalar los programas basicos? [y/n] " yesno
        case $yesno in
            [Yy]* ) \
                for x in curl ca-certificates base-devel git ntp zsh ; do
                    pacman_installer "$x" "programa basico para instalar o configurar otros programas";
                done; break;;
            [Nn]* ) break;;
            * ) echo "Solo se acepta [y]es o [n]o";;
        esac
    done
}

ask_install() { # Preguntar si se debe instalar programas
    while true; do
        read -p "> Desea instalar todos los programas? [y/n] " yesno
        case $yesno in
            [Yy]* ) instalador || exit 1; break;;
            [Nn]* ) break;;
            * ) echo "Solo se acepta [y]es o [n]o";;
        esac
    done
}

instalador() { # loop para instalar codigo sacado de larbs de Luke Smith
    # primero instalar yay como aur helper
    installyay || salir "No se pudo instalar yay"
    ([ -f "$programas" ] && cp "$programas" /tmp/programas.csv) || curl -Ls "$programas" | sed '/^#/d' > /tmp/programas.csv
    aur_installed=$(pacman -Qqm)
    # loop
    while IFS=, read -r tag program comment; do
        echo "$comment" | grep -q "^\".*\"$" && comment="$(echo "$comment" | sed -E "s/(^\"|\"$)//g")"
        case "$tag" in
            "A") yay_installer "$program" "$comment" ;;
            "G") git_installer "$program" "$comment" ;;
            *) pacman_installer "$program" "$comment" ;;
        esac
    done < /tmp/programas.csv ;
}

installyay() { # aur helper para instalar otros programas
    echo -e "Instalando yay desde la AUR"
    export repodir="/home/$user/awesometimes/repos"; mkdir -p "$repodir"
    cd "$repodir" || exit 1
    git clone "https://aur.archlinux.org/yay.git"
    cd yay; makepkg --noconfirm -si >/dev/null 2>&1
    echo -e "yay descargado satisfactoriamente."
    echo ""
}

pacman_installer() {
    echo -e "\nInstalando \`\033[1m$1\033[0m\` $2" # 1 programa # 2 comment
    pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

yay_installer() {
    echo -e "\nInstalando ($n de $total) desde la AUR \`\033[1m$1\033[0m\` $2"
    echo "$aur_installed" | grep -q "^$1$" && return 1
    yay -S --noconfirm "$1" >/dev/null 2>&1
}

git_instalador() { # algo falla aqui...
    progname="$(basename "$1" .git)"
    dir="$repodir/$progname"
    echo -e "\nInstalando ($n de $total) usando git y make. $(basename "$1") $2"
    cd "$repodir";
    git clone $1
    cd "$dir" || exit 1
    make >/dev/null 2>&1
    make install >/dev/null 2>&1
    cd /tmp || return 1 ;
}

dotfiles_install() { # Descarga e instala los dotfiles de mi perfil
    while true; do
        read -p "> Instalar awtgerry dotfiles? (ten en cuenta que configuracion anterior se perdera) [y/n] " yesno
        case $yesno in
            [Yy]* ) \
                echo -e "Instalando dotfiles"
                cd "/home/$user"
                git clone "$dotfiles"
                cp -rf ".dotfiles/." "~"
                rm -rf ~/install.sh ~/.git ~/README.md; break;;
            [Nn]* ) break;;
            * ) echo "Solo se acepta [y]es o [n]o";;
        esac
    done
}

# Funciones para mostrar estado de bateria para laptops
add_battery() {
    while true; do
        read -p "> Desea agregar funciones para bateria? [y/n] " yesno
        case $yesno in
            [Yy]* ) sed -i 's/# upperbar="$upperbar$(dwm_battery)"/upperbar="$upperbar$(dwm_battery)"/' ~/.config/dwm/dwmbar/dwm_bar.sh; \
                sed -i 's/# batdunst --status &/batdunst --status &' ~/.xprofile; break;;
            [Nn]* ) break;;
            * ) echo "Solo se acepta [y]es o [n]o";;
        esac
    done
}

ask_default_install || salir "no se pude completar la instalacion"
ask_install || salir "programa finalizado por el usuario"
dotfiles_install || salir "no se pudo descargar dotfiles"
add_battery || salir "no se pudo agregar funciones de bateria"

sed -i "s/gerry/$user/" ~/.config/dunst/dunstrc
sed -i "s/gerry/$user/" ~/.config/nvim/init.lua

echo -e "Adios a la campanita enfadosa"
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;}

# notificaciones de brave
echo "export \$(dbus-launch)" > /etc/profile.d/dbus.sh

# zsh como shell
chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/zsh/"
sudo -u "$name" mkdir -p "/home/$name/.config/abook/"
sudo -u "$name" mkdir -p "/home/$name/.config/mpd/playlists/"

# runit
# dbus-uuidgen > /var/lib/dbus/machine-id

echo -e "Instalacion terminada :)"
