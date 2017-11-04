wget https://github.com/migasfree/migasfree-client/archive/master.zip
unzip master.zip
rm master.zip
cd migasfree-client-master/bin


# BUGFIX 1
_DISTRO=$(python -c "import platform; print platform.linux_distribution()[0].strip()")
echo $_DISTRO && \
mv ../setup.cfg.d/CentOS "../setup.cfg.d/$_DISTRO"


# BUGFIX 2
echo "gtk-update-icon-cache --quiet /usr/share/icons/hicolor/ || : "  > ../scripts/rpm-post-install.sh


./create-package
