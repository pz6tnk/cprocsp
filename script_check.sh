/opt/cprocsp/bin/amd64/certmgr -install -file /var/www/as.opti-24.lc/libphpcades/cades_test.pfx -pfx -pin 123
/opt/cprocsp/bin/amd64/certmgr -inst -store uRoot -file /var/www/as.opti-24.lc/libphpcades/root2018.crt
php /opt/cprocsp/src/phpcades/test_extension.php
