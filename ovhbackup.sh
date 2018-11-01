#!/bin/sh
TEST=ovhbackup

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
	if [ -f ${BBTMP}/ovhbackup_file.msg ]; then
		$RM ${BBTMP}/ovhbackup_file.msg
	fi
fi

$RM -f ${BBTMP}/ovhbackup.msg

#Tests de base
LOGIN_FILE=${HOBBITCLIENTHOME}/etc/ovhbackup_login.cfg
RETENTION=17
RETENTION_MINIMAL=5

if [ ! -w ${BBTMP} ] ; then
        echo "Impossible d ecrire dans ${BBTMP} !" >&2
        exit 2
fi  

if [ -f ${BBTMP}/.banner ] ; then
	echo "Le fichier ${BBTMP}/.banner existe deja !" >&2
	exit 2
fi

if [ ! -r $LOGIN_FILE ] ; then
	echo "Impossible de lire le fichier ${LOGIN_FILE} !" >&2
	exit 2
fi
	
#Recuperation des donnees sur le serveur de backup
ncftpget -V -f ${LOGIN_FILE} ${BBTMP} .banner
USED=$($AWK '{print $11}' ${BBTMP}/.banner)
TOTAL=$($AWK '{print $16}' ${BBTMP}/.banner)
STILL=$($AWK "BEGIN{print $TOTAL - $USED}")
PERCENT=$($AWK "BEGIN{print $USED / $TOTAL * 100}")
TRUNC_PERCENT=$(echo $PERCENT | $AWK -F\. '{print $1}')

#Calcul de la taille de la derniere sauvegarde
for DIR in boot dns etc mail mysql scripts www xymon-plugins ; do
	let TODAY_RAW_BACKUP_SIZE+=$(ncftpls -l -f $LOGIN_FILE ftp://ftpback-rbx3-176.ovh.net/kyle/$DIR-backup/*$($DATE +%F).tar.bz2 | $AWK '{print $5}')
done

let  TODAY_BACKUP_SIZE=TODAY_RAW_BACKUP_SIZE/1024

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

if [ -f ${BBTMP}/.banner ]; then
	$RM ${BBTMP}/.banner
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

#Affichage des donnees de base
echo "Retention: $RETENTION jours
Espace utilise: ${USED} ko
Espace restant: ${STILL} ko

&$PERCENT_STATUS Pourcentage :
Utilisation: ${PERCENT}

&$NEXT_BACKUP $NEXT_BACKUP_MSG :
Taille_derniere_sauvegarde: $TODAY_BACKUP_SIZE" >> ${BBTMP}/ovhbackup.msg

#Verification de la presence des fichiers
for DIR in boot dns etc mail mysql scripts www xymon-plugins ; do
		LIST=$(ncftpls -l -f $LOGIN_FILE ftp://ftpback-rbx3-176.ovh.net/kyle/$DIR-backup/)
	for NOMBRE in $(seq -w $RETENTION_MINIMAL $RETENTION) ; do
		DATE_TO_CHECK="$("$DATE" --date="$NOMBRE days ago" +%F)"
		echo $LIST |$GREP -q ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2
		if [ $? -ne 0 ] ; then
			YELLOW=1
			FILE_YELLOW=1
			echo "&yellow ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2" >> ${BBTMP}/ovhbackup_file.msg
		fi
	done
	for NOMBRE in $(seq 1 $RETENTION_MINIMAL) ; do
		DATE_TO_CHECK="$("$DATE" --date="$NOMBRE days ago" +%F)"
		echo $LIST |$GREP -q ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2
		if [ $? -ne 0 ] ; then
			RED=1
			FILE_RED=1
			echo "&red ${DIR}-backup-${DATE_TO_CHECK}.tar.bz2" >> ${BBTMP}/ovhbackup_file.msg
		fi
	done
done
if [ $FILE_RED ] ; then
	echo "
&red Il manque des fichiers recents sur le FTP OVH !!!
Voici la liste :" >> ${BBTMP}/ovhbackup.msg
	$CAT ${BBTMP}/ovhbackup_file.msg >> ${BBTMP}/ovhbackup.msg
elif [ $FILE_YELLOW ] ; then
	echo "
&yellow Il manque des fichiers anciens sur le FTP OVH !" >> ${BBTMP}/ovhbackup.msg
	$CAT ${BBTMP}/ovhbackup_file.msg >> ${BBTMP}/ovhbackup.msg
else
	echo "
&green Tous les fichiers sont presents sur le FTP OVH" >> ${BBTMP}/ovhbackup.msg
fi

if [ $RED ] ; then
	STATUS=red
elif [ $YELLOW ] ; then
	STATUS=yellow
else
	STATUS=green
fi

if [ -z $1 ] && [ -f ${BBTMP}/ovhbackup_file.msg ] ; then
	$RM ${BBTMP}/ovhbackup_file.msg
fi

"$BB" "$BBDISP" "status "$MACHINE"."$TEST" "$STATUS" $("$DATE")

$($CAT ${BBTMP}/ovhbackup.msg)
"
