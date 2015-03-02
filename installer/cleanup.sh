echo "DANGER!  This will delete your WebGUI site and all of its data, and your mysql config too, and probably other things."
echo "It's used by the DEVELOPERS for testing the installer.  Hit control-C now if you don't want to delete your database!"
echo "Hit enter to nuke everything."

read line

rm -f /etc/my.cnf
rm -rf /etc/mysql
rm -rf /data
rm -rf /etc/nginx
rm -f /etc/nginx/conf.d/webgui8.conf
rm -f /usr/local/etc/nginx/conf.d/webgui8.conf
rm -f /etc/rc.d/*/*webgui8
rm -f /data/WebGUI/etc/*.nginx
rm -rf /tmp/WebGUICache
killall starman
# mysql --user=root --password=Nyklm6 -e 'drop database www_example_com;'
rm -rf /var/lib/mysql
apt-get remove akonadi-backend-mysql  libdbd-mysql-perl libmysqlclient18:amd64 mysql-client-5.5 mysql-common mysql-server-core-5.5
userdel webgui
