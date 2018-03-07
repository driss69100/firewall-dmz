# firewall-dmz
Script iptables firewall-dmz works with Debian
Après le téléchargement, décompressez le fichier,
Vous aurez trois fichiers :
flush.sh
fw.sh
fw
Le fichier nommé "flush.sh" permet de nettoyer toutes les tables iptables, donc celui qui permet de désactiver le firewall, le deuxième nommé fw.sh celui qui permet de mettre en place toutes les règles iptables, et le troisième fichier sans extension nommé fw, est un script permet d’exécuter automatiquement les deux premiers fichier à l’extinction du système et au redémarrage.
Création d’un repertoire « fw » dans /etc
#mkdir /etc/fw
Emplacement des fichiers :
Copier les deux premiers fichiers dans /etc/fw
# ls /etc/fw
flush.sh  fw.sh
Copier le script de demarrage dans /etc/init.d/fw
#ls /etc/init.d
fw
Droits d’exécution sur les trois fichiers :
#chmod +x /etc/fw/flush.sh
#chmod +x /etc/fw/fw.sh
#chmod +x /etc/init.d/fw
Mettre à jour le fichier dans init.d :
#update-rc.d  fw defaults 90
Adapter les interfaces réseaux avec les variables dans les fichiers /etc/fw/flush.sh et /etc/fw/fw.sh
#Variables :
INT_EXT=eth0		>remplacer l’interface WAN eth0 par votre interface WAN
INT_LOCAL=eth1	>remplacer l’interface LAN eth1 par votre interface LAN
INT_DMZ=eth2		>remplacer l’interface DMZ eth2 par votre interface DMZ
Maintenant vous pouvez redémarrer le système et tout se mettra en place automatiquement.
Pour activer le firewall manuellement tapez :
#sh –x /etc/fw/fw.sh
Pour désactiver le firewall manuellement tapez :
#sh –x /etc/fw/flush.sh
Chaque redémarrage activera automatiquement le firewall.
