wget https://github.com/migasfree/migasfree-client/archive/master.zip
unzip master.zip
rm master.zip
cd migasfree-client-master/bin


# BUGFIX 1
echo "gtk-update-icon-cache --quiet /usr/share/icons/hicolor/ || : "  > ../scripts/rpm-post-install.sh

# BUGFIX 2
echo "gtk-update-icon-cache --quiet /usr/share/icons/hicolor/ || : "  > ../scripts/rpm-post-uninstall.sh


./create-package
