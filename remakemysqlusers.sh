#WordPress 'Remake MySQL Users' Script for cPanel
#Please call this script like so: sh (script) (domain)
#You can change the dbextension or usrextension to whatever you want :)
dbextension="_wpress"
userextension="_usr"
#grab domain, user
mydomain=$1;
myuser=`/scripts/whoowns $mydomain`;
passwd=`tr -cd '[:alnum:]!@#$%^&*()<>?' < /dev/urandom | fold -w12 | head -n1`;
wpconf="/home/$myuser/public_html/wp-config.php";
#check for critical errors like the wrong domain or usernames >8 characters
if [[ $myuser == "" ]]; then 
  echo "No user for this domain!"; exit 1; 
fi
if [[ ${#myuser} -gt 8 ]]; then 
  mynameuser=`echo $mydomain | fold -w8 | head -n1`; 
else 
  mynameuser=`echo $myuser`; 
fi
if [[ -f $wpconf ]]; then 
  echo "wpconf OK"; 
else 
  echo "No wpconf available in default location!"; 
  exit 1; 
fi
#set the rest of the variables we need to UAPI it up
olddbname=$(grep DB_NAME $wpconf | cut -d"'" -f4)
dbname=`echo $mynameuser$dbextension`;
dbusr=`echo $mynameuser$userextension`;
#create the user, db, and set privileges
uapi --user=$myuser Mysql create_database name=$dbname;
uapi --user=$myuser Mysql create_user name=$dbusr password=$passwd;
uapi --user=$myuser Mysql set_privileges_on_database user=$dbusr database=$dbname privileges="ALL PRIVILEGES";
#check for file existing and if it doesn't, dump stuff and then import it
if [[ -f /home/$myuser/$olddbname.wpscript ]]; then 
  echo "DB backup location not OK, did you run this script before?"; 
  exit 1; 
else 
  echo "DB Backup location OK";
fi
mysqldump $olddbname > /home/$myuser/$olddbname.wpscript
mysql $dbname < /home/$myuser/$olddbname
rm -f /home/$myuser/$olddbname
echo "we are grabbing info from $wpconf for user $myuser and are making this for $dbname and $dbusr with password $passwd"
echo "Please replace the password/user/etc. with the new values in wpconfig listed above and test. Then, if it works, run this: echo 'drop database $olddbname' | mysql . Thanks\!"
