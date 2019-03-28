wget https://github.com/migasfree/migasfree-client/archive/master.zip
unzip master.zip
rm master.zip
cd /migasfree-client-master/bin
./create-package
cp /migasfree-client-master/dist/*.rpm /dist
