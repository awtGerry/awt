#!/bin/sh

dotfiles="https://github.com/awtGerry/.dotfiles"
programas="https://raw.githubusercontent.com/awtGerry/awt/master/programas.csv"
welcome="https://raw.githubusercontent.com/awtGerry/awt/master/welcome.txt"

([ -f "$welcome" ] && cp "$welcome" /tmp/welcome.txt) || curl -Ls "$welcome" | sed '/^#/d' > /tmp/welcome.txt
cat /tmp/welcome.txt
echo -e "Instalador de dotfiles y programas para arch/artix linux"
echo -e "## Para que el instalador funcione por completo tiene que ser ejecutado con permisos de root ##"

# Usuario ingresa nombre y contrasena
# TODO: implementar esto para que sea desde una instalacion en blanco de arch.
echo -e "> Ingrese nombre de usuario: \c"
read user
echo -e "> Ingrese contraseña [sudo] de $user: \c"
read -s pass
echo ""
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
                for x in curl ca-certificates base-devel git ntp zsh ninja; do
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
    sudo pacman -Syy
    installyay || salir "No se pudo instalar yay"
    ([ -f "$programas" ] && cp "$programas" /tmp/programas.csv) || curl -Ls "$programas" | sed '/^#/d' > /tmp/programas.csv
    total=$(wc -l < /tmp/programas.csv)
    aur_installed=$(pacman -Qqm)
    # loop
    while IFS=, read -r tag program comment; do
        n=$((n+1))
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
    sudo -u "$user" git clone "https://aur.archlinux.org/yay.git"
    cd yay
    sudo -u "$user" makepkg --noconfirm -si >/dev/null 2>&1
    echo -e "yay descargado satisfactoriamente."
    echo ""
}

pacman_installer() {
    echo -e "\nInstalando \`\033[1m$1\033[0m\` $2 ($n de $total)" # 1 programa # 2 comment
    pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

yay_installer() {
    echo -e "\nInstalando desde la AUR \`\033[1m$1\033[0m\` $2 ($n de $total)"
    echo "$aur_installed" | grep -q "^$1$" && return 1
    yay -S --noconfirm "$1" >/dev/null 2>&1
}

git_installer() {
    progname="$(basename "$1" .git)"
    dir="$repodir/$progname"
    echo -e "\nInstalando usando git y make. $(basename "$1") $2 ($n de $total)"
    cd "$repodir";
    sudo -u "$user" git clone $1
    cd "$dir" || exit 1
    make >/dev/null 2>&1
    make clean install >/dev/null 2>&1
    cd /tmp || return 1 ;
}

dotfiles_install() { # Descarga e instala los dotfiles de mi perfil
    while true; do
        read -p "> Instalar awtgerry dotfiles? (ten en cuenta que configuracion anterior se perdera) [y/n] " yesno
        case $yesno in
            [Yy]* ) \
                echo -e "Instalando dotfiles..."
                git clone --depth 1 "$dotfiles" "/home/$user"
                sudo -u "$user" cp -rfT "/home/$user/.dotfiles/". "/home/$user/".
                rm -rf /home/"$user"/install.sh /home/"$user"/.git /home/"$user"/README.md \
                    /home/"$user"/.gitignore; break;;
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
            [Yy]* ) sed -i 's/# upperbar="$upperbar$(dwm_battery)"/upperbar="$upperbar$(dwm_battery)"/' /home/"$user"/awesometimes/repos/dwmbar/dwm_bar.sh; \
                sed -i 's/# batdunst/batdunst/' /home/"$user"/.xprofile; break;;
            [Nn]* ) break;;
            * ) echo "Solo se acepta [y]es o [n]o";;
        esac
    done
}

install_sumneko_lua() {
    while true; do
        read -p "> Instalar lsp de lua? (necesario para neovim)? [y/n] " yesno
        case $yesno in
            [Yy]* ) \
                echo -e "Instalando lua-language-server"
                lib="/home/$user/.local/lib"
                mkdir -p "$lib"; cd "$lib"
                git clone  --depth=1 https://github.com/sumneko/lua-language-server
                cd lua-language-server
                git submodule update --depth 1 --init --recursive
                cd 3rd/luamake
                ./compile/install.sh
                cd ../..
                ./3rd/luamake/luamake rebuild
                echo -e "LSP de lua fue instalado correctamente"; break;;
            [Nn]* ) break;;
            * ) echo "Solo se acepta [y]es o [n]o";;
        esac
    done
}

install_packer() {
    while true; do
        read -p "> Instalar packer.nvim? (necesario para neovim)? [y/n] " yesno
        case $yesno in
            [Yy]* ) \
                echo -e "Instalando packer.nvim desde git by wbthomason"
                sudo -u "$user" git clone --depth 1 https://github.com/wbthomason/packer.nvim\
                    /home/"$user"/.local/share/nvim/site/pack/packer/start/packer.nvim
                echo -e "Packer fue instalado correctamente"; break;;
            [Nn]* ) break;;
            * ) echo "Solo se acepta [y]es o [n]o";;
        esac
    done
}

ask_default_install || salir "no se pude completar la instalacion"
ask_install || salir "programa finalizado por el usuario"
dotfiles_install || salir "no se pudo descargar dotfiles"
add_battery || salir "no se pudo agregar funciones de bateria"
install_sumneko_lua || salir "no se pudo instalar sumneko lua"
install_packer || salir "no se pudo instalar packer.nvim"

sed -i "s/user/$user/" /home/"$user"/.config/dunst/dunstrc
sed -i "s/user/$user/" /home/"$user"/.config/nvim/init.lua
sudo -u "$user" mkdir -p "/home/$user/.cache/zsh"
sudo -u "$user" mkdir -p "/home/$user/.cache/nvim/undodir"

# notificaciones de brave
echo "export \$(dbus-launch)" > /etc/profile.d/dbus.sh

grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf
# zsh como shell
chsh -s /bin/zsh "$user" >/dev/null 2>&1
sudo -u "$user" mkdir -p "/home/$user/.cache/zsh/"
sudo -u "$user" mkdir -p "/home/$user/.config/abook/"
sudo -u "$user" mkdir -p "/home/$user/.config/mpd/playlists/"

# artix con runit
# dbus-uuidgen > /var/lib/dbus/machine-id

sudo -u "$user" xwallpaper --zoom /home/"$user"/.local/share/bg

echo -e "Instalacion terminada :)"
