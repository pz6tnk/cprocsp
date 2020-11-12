yum install -y lsb
cd /var/www/as.opti-24.lc/libphpcades/linux-amd64/
chmod +x install.sh
./install.sh
yum install -y cprocsp-rsa-64-4.0.9944-5.x86_64.rpm
cd /var/www/as.opti-24.lc/libphpcades/
yum install -y cprocsp-pki-cades-64-2.0.14071-1.amd64.rpm
yum install -y cprocsp-pki-phpcades-64-2.0.14071-1.amd64.rpm
cp libphpcades.so /usr/lib64/php/modules/
sed -i '/; Dynamic Extensions ;/a extension=libphpcades.so' /etc/php.ini
