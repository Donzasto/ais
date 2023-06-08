#!/bin/bash
DRIVE='/dev/sd '
setup() {
fdisk $DRIVE << EOF
g
n


+300M
t
1
n



w
EOF
mkfs.fat -F32 "$DRIVE"1
mkfs.ext4 "$DRIVE"2
mount "$DRIVE"2 /mnt
mkdir /mnt/boot
mount "$DRIVE"1 /mnt/boot
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
cp $0 /mnt/s.sh
arch-chroot /mnt ./s.sh chroot
reboot
}

configure() {
pacman -S dhcpcd sudo vim plasma yakuake dolphin sddm packagekit-qt5 bluez bluez-utils pulseaudio-bluetooth ufw firefox keepassxc ntfs-3g libreoffice-still vlc adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-emoji krita nvidia-open spectacle gwenview kcalc grub efibootmgr git github-cli ovmf qemu-full << EOF






EOF
systemctl enable dhcpcd.service sddm bluetooth.service
sed -i -e 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
ln -sT /usr/share/zoneinfo/Europe/Moscow /etc/localtime
echo "Enter password for root"
passwd
read -p "Enter username: " username
useradd -m $username
echo "Enter password for" $username
passwd $username
echo "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$username ALL=(ALL) ALL/" | EDITOR="sed -f- -i" visudo
mkdir /boot/efi
mount "$DRIVE"1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
#Убрать гул(треск) из динамиков
sed -i "s/load-module module-suspend-on-idle/#load-module module-suspend-on-idle/" /etc/pulse/default.pa
#Переключение с nouveau на nvidia drivers
echo -e "blacklist nouveau\noptions nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf
mkinitcpio -p linux
#Скрыть boot menu
sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/" /etc/default/grub
sed -i "s/GRUB_TIMEOUT_STYLE=menu/GRUB_TIMEOUT_STYLE=hidden/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
rm s.sh
exit
}

if [ "$1" == "chroot" ]
then
  configure
else
  setup
fi
