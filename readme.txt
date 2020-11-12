На целевом сервере необходимо сделать следующее:
поместить папку libphpcades в каталог /home/test/ (либо изменить пути на свои)
запустить script.sh:
chmod +x /home/test/libphpcades/script.sh
/home/test/libphpcades/script.sh

Для проверки работоспособности:

запустить script_check.sh:
chmod +x /home/test/libphpcades/script_check.sh
/home/test/libphpcades/script_check.sh

в результате выполнения должен быть запрошен пин-код от контейнера (123) и выведено сообщение TEST OK