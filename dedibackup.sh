#!/bin/bash
TEST=backup
#Definition des variables :
#Client LFTP
LFTP=/usr/bin/lftp
#Quota dedibox en Mo
DEDI_QUOTA=200000
#Retention souhaitee des donnees :
RETENTION=15
#Retention minimale :
RETENTION_MINIMAL=5
#Intervalle entre les tests :
INTERVAL=1d

if [ "$1" == "debug" ] ; then
        echo "Debug ON"
        BB=echo
	CAT="/bin/cat"
        HOBBITCLIENTHOME="/usr/local/Xymon/client"
        #BBTMP="$PWD"
	BBTMP=.
        BBDISP=your_hobbit_server
        MACHINE=$(hostname)
        AWK="/usr/bin/awk"
        RM="/bin/rm"
        DATE="/bin/date"
	GREP="/bin/grep"
fi

if [ -f ${BBTMP}/dedibackup.msg ] ; then
	$RM -f ${BBTMP}/dedibackup.msg
fi
if [ -f ${BBTMP}/dedibackup_file.msg ] ; then
	$RM ${BBTMP}/dedibackup_file.msg
fi
if [ -f ${BBTMP}/dedibackup_size.msg ] ; then
	$RM ${BBTMP}/dedibackup_size.msg
fi


#Tests de base
LOGIN_FILE=${HOBBITCLIENTHOME}/etc/dedibackup_login.cfg
DATE="/bin/date"
AWK="/usr/bin/awk"

if [ ! -w ${BBTMP} ] ; then
        echo "Impossible d ecrire dans ${BBTMP} !" >&2
        exit 2
fi  

if [ ! -r $LOGIN_FILE ] ; then
	echo "Impossible de lire le fichier ${LOGIN_FILE} !" >&2
	exit 2
fi
	
#Recuperation des donnees sur le serveur de backup
USED_RAW=$("$LFTP" -c "connect dedibackup ; du -sm")
USED=$(echo $USED_RAW | $AWK '{print $1}')
TOTAL=$DEDI_QUOTA
STILL=$($AWK "BEGIN{print $TOTAL - $USED}")
PERCENT=$($AWK "BEGIN{print $USED / $TOTAL * 100}")
TRUNC_PERCENT=$(echo $PERCENT | $AWK -F\. '{print $1}')



#Calcul de la taille de la derniere sauvegarde
TODAY_RAW_BACKUP_SIZE=0
for DIR in boot dns etc mail mysql scripts www xymon-plugins ; do
	let TODAY_RAW_BACKUP_SIZE+=$(ncftpls -l -f $LOGIN_FILE ftp://dedibackup-vit.online.net/cartman/$DIR-backup/*$($DATE +%F).tar.bz2 | $AWK '{print $5}')
done

let TODAY_BACKUP_SIZE=$TODAY_RAW_BACKUP_SIZE/1000000

#Verification de la place disponible
if [ $TRUNC_PERCENT -lt 95 ] ; then
	PERCENT_STATUS=green
elif [ $TRUNC_PERCENT -ge 95 ] && [ $TRUNC_PERCENT -lt 98 ] ; then
	PERCENT_STATUS=yellow
	YELLOW=1
elif [ $TRUNC_PERCENT -ge 98 ] ; then
	PERCENT_STATUS=red
	RED=1
else
	echo "La valeur TRUNC_PERCENT n est pas correcte : $TRUNC_PERCENT" >&2
	exit 2
fi

#Verification de la possibilite de stocker la prochaine sauvegarde, en extrapolant de la taille de celle du jour
if [ $STILL -le $TODAY_BACKUP_SIZE ] ; then
	NEXT_BACKUP=red
	RED=1
	NEXT_BACKUP_MSG="L'espace restant ne semble pas suffisant pour la prochaine sauvegarde"
else
	NEXT_BACKUP=green
	NEXT_BACKUP_MSG="L'espace restant semble suffisant pour la prochaine sauvegarde"
fi

#Verification de la taille des sauvegardes
BACKUP_SIZE=0
for DIR in boot dns etc mail mysql scripts www xymon-plugins ; do
        BACKUP_SIZE=$(ncftpls -l -f $LOGIN_FILE ftp://dedibackup-vit.online.net/cartman/$DIR-backup/*$($DATE +%F).tar.bz2 | $AWK '{print $5}')
	if [ $BACKUP_SIZE -eq 0 ] ; then
		RED=1
		BACKUP_SIZE_COLOR=red
		echo "&red La taille de $DIR-backup-$($DATE +%F).tar.bz2 est zero !" >> ${BBTMP}/dedibackup_size.msg
	fi
done
if [ -z $BACKUP_SIZE_COLOR ] ; then
	BACKUP_SIZE_COLOR=green
	echo "La taille des sauvegardes est non nulle" >> ${BBTMP}/dedibackup_size.msg
fi

#Affichage des donnees de base
echo "Retention: $RETENTION jours
Espace utilise: $USED Mo
Espace restant: $STILL Mo
Taille derniere sauvegarde: $TODAY_BACKUP_SIZE Mo

&$PERCENT_STATUS Pourcentage :
Utilisation: $PERCENT

&$NEXT_BACKUP $NEXT_BACKUP_MSG :
Taille_derniere_sauvegarde: $TODAY_BACKUP_SIZE

&$BACKUP_SIZE_COLOR Verification de la taille des sauvegardes :
$($CAT ${BBTMP}/dedibackup_size.msg)" >> ${BBTMP}/dedibackup.msg

#Verification de la presence des fichiers
RETENTION_MINIMAL_PLUS=$RETENTION_MINIMAL
let RETENTION_MINIMAL_PLUS+=1
for DIR in boot dns etc mail mysql scripts www xymon-plugins ; do
		LIST=$(ncftpls -l -f $LOGIN_FILE ftp://dedibackup-vit.online.net/cartman/$DIR-backup/)
	for NOMBRE in $(seq 0 $RETENTION_MINIMAL) ; do
		DATE_TO_CHECK="$("$DATE" --date="$NOMBRE days ago" +%F)"
		echo $LIST |$GREP -q ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2
		if [ $? -ne 0 ] ; then
			RED=1
			FILE_RED=1
			echo "&red ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2" >> ${BBTMP}/dedibackup_file.msg
		fi
	done
	for NOMBRE in $(seq -w $RETENTION_MINIMAL_PLUS $RETENTION) ; do
		DATE_TO_CHECK="$("$DATE" --date="$NOMBRE days ago" +%F)"
		echo $LIST |$GREP -q ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2
		if [ $? -ne 0 ] ; then
			YELLOW=1
			FILE_YELLOW=1
			echo "&yellow ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2" >> ${BBTMP}/dedibackup_file.msg
		fi
	done
done
if [ $FILE_RED ] ; then
	echo "
&red Il manque des fichiers recents sur le FTP Dedibackup !!!
Voici la liste :" >> ${BBTMP}/dedibackup.msg
	sort ${BBTMP}/dedibackup_file.msg >> ${BBTMP}/dedibackup.msg
elif [ $FILE_YELLOW ] ; then
	echo "
&yellow Il manque des fichiers anciens sur le FTP Dedibackup !" >> ${BBTMP}/dedibackup.msg
	$CAT ${BBTMP}/dedibackup_file.msg >> ${BBTMP}/dedibackup.msg
else
	echo "
&green Tous les fichiers sont presents sur le FTP Dedibackup" >> ${BBTMP}/dedibackup.msg
fi

if [ $RED ] ; then
	STATUS=red
elif [ $YELLOW ] ; then
	STATUS=yellow
else
	STATUS=green
fi

"$BB" "$BBDISP" "status+"$INTERVAL" "$MACHINE"."$TEST" "$STATUS" $("$DATE")


$($CAT ${BBTMP}/dedibackup.msg)
"
