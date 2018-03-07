#!/bin/sh
####################################################################################
################## Objet:	PARE-FEU-DMZ								############
################## Auteur:	Driss BENELKAID								############
################## Usage:	Libre pour tout le monde					############
################## version:	0.7 	07/03/18							############
####################################################################################
# Variables:
INT_EXT=eth0
INT_LOCAL=eth1
INT_DMZ=eth2
SRV_SFTP=10.100.30.30
P_SSH=2222
#
# Supprimer les paramétrages existants
iptables -F
iptables -X/
iptables -t nat -F
iptables -t nat -X
#
# Fermer les entrées, sorties et transits. A partir de maintenant tout est refusé
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
#
# On autorise le PARE-FEU à s'appeler lui-même
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
#
# On définit des chaînes utilisateurs, ce n'est pas indispensable, mais facilitera la lecture
# des autorisations, elles indiquent un chemin : d'où on vient et où on va
iptables -N inet-dmz
iptables -N local-dmz
iptables -N dmz-inet
iptables -N dmz-local
iptables -N local-inet
iptables -N inet-local # Uniquement pour certains service spécifiés
#
# On associe une action (ici le transit d une interface à l'autre) à chaque chaîne utilisateur
iptables -A FORWARD -i ${INT_EXT} -o ${INT_DMZ} -j inet-dmz
iptables -A FORWARD -i ${INT_LOCAL} -o ${INT_DMZ} -j local-dmz
iptables -A FORWARD -i ${INT_DMZ} -o ${INT_EXT} -j dmz-inet
iptables -A FORWARD -i ${INT_DMZ} -o ${INT_LOCAL} -j dmz-local
iptables -A FORWARD -i ${INT_LOCAL} -o ${INT_EXT} -j local-inet
iptables -A FORWARD -i ${INT_EXT} -o ${INT_LOCAL} -j inet-local # Uniquement pour certains services
#
# ICMP: Les ping depuis et vers le PARE-FEU
iptables -A OUTPUT -o ${INT_EXT} -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i ${INT_EXT} -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o ${INT_DMZ} -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i ${INT_DMZ} -p icmp -j ACCEPT # --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o ${INT_LOCAL} -p icmp -j ACCEPT
iptables -A INPUT -i ${INT_LOCAL} -p icmp -j ACCEPT
#
# ICI je rajoutrai une règle pour le serveur de tempt NTP: 
iptables -A OUTPUT -o ${INT_EXT} -p udp --dport 123 -j ACCEPT
iptables -A INPUT -i ${INT_EXT} -p udp --sport 123 -j ACCEPT
#
# NTP serveur de temps pour local:
iptables -A local-inet -p udp --dport 123 -j ACCEPT
iptables -A inet-local -p udp --sport 123 -j ACCEPT
# 
# ICMP FORWARDING: Les ping entre les 3 interfaces (vers local non autorisé):
iptables -A local-dmz -p icmp --icmp-type echo-request -j ACCEPT
iptables -A local-inet -p icmp --icmp-type echo-request -j ACCEPT
iptables -A inet-dmz -p icmp -j ACCEPT
iptables -A dmz-inet -p icmp --icmp-type echo-request -j ACCEPT
iptables -A inet-local -p icmp -j ACCEPT # ping sens inet-local non autorisé par règle echo-request
iptables -A dmz-local -p icmp -j ACCEPT # ping sens dmz-local non autorisé par règle echo-request
#
# DNS FORWARDING: local et DMZ vers Internet
iptables -A local-inet -p udp --dport domain -j ACCEPT
iptables -A inet-local -p udp --sport domain -j ACCEPT
iptables -A dmz-inet -p udp --dport domain -j ACCEPT
iptables -A inet-dmz -p udp --sport domain -j ACCEPT
#
# DNS OUTPUT :
iptables -A OUTPUT -o ${INT_EXT} -p udp --dport domain -j ACCEPT
#
# Ne pas casser les connexions établiées sur le PARE-FEU E-S de local
iptables -A INPUT -i ${INT_EXT} -m state --state ESTABLISHED,RELATED -j ACCEPT # accès ssh en dmz
iptables -A OUTPUT  -o ${INT_EXT} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i ${INT_LOCAL} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o ${INT_LOCAL} -m state --state ESTABLISHED,RELATED -j ACCEPT
#
# SSH vers SRV_SFTP en dmz
iptables -A inet-dmz -p tcp -d $SRV_SFTP --dport $P_SSH -j ACCEPT
iptables -A dmz-inet -p tcp  --sport $P_SSH -j ACCEPT
iptables -A local-dmz -p tcp -d $SRV_SFTP --dport $P_SSH -j ACCEPT
iptables -A dmz-local -p tcp --sport $P_SSH -j ACCEPT
#
# SSH sur PARE-FEU seulement depuis local
iptables -i ${INT_EXT} -A INPUT -p tcp --dport $P_SSH -j ACCEPT # sera redirigee vers SRV_SFTP en dmz
iptables -i ${INT_LOCAL} -A INPUT -p tcp --dport $P_SSH -j ACCEPT
#
# Serveurs distants FTP
iptables -A local-inet -p tcp --dport 21 -j ACCEPT
iptables -A inet-local -p tcp --sport 21 -j ACCEPT
iptables -A local-inet -p tcp --dport 20 -j ACCEPT
iptables -A inet-local -p tcp --sport 20 -j ACCEPT
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
#
# FORWARDING HTTP HTTPS dmz vers Internet #  local vers Internet # PARE-FEU vers Internet
iptables -A dmz-inet -p tcp --dport http -j ACCEPT
iptables -A dmz-inet -p tcp --dport https -j ACCEPT
iptables -A inet-dmz -p tcp --sport http -j ACCEPT
iptables -A inet-dmz -p tcp --sport https -j ACCEPT
iptables -A local-inet -p tcp --dport http -j ACCEPT
iptables -A local-inet -p tcp --dport https -j ACCEPT
iptables -A inet-local -p tcp --sport http -j ACCEPT
iptables -A inet-local -p tcp --sport https -j ACCEPT
iptables -o ${INT_EXT} -A OUTPUT -p tcp --dport http -j ACCEPT # pour apt-get update
iptables -o ${INT_EXT} -A OUTPUT -p tcp --dport https -j ACCEPT # pour apt-get update
#
# MAILS : 
# 1 SMTP :
iptables -A local-inet -p tcp --dport 25 -j ACCEPT # SMTP sans chiffrement
iptables -A inet-local -p tcp --sport 25 -j ACCEPT # SMTP sans chiffrement
iptables -A local-inet -p tcp --dport 587 -j ACCEPT # SMTP avec chiffrement
iptables -A inet-local -p tcp --sport 587 -j ACCEPT # SMTP avec chiffrement
iptables -A local-inet -p tcp --dport 465 -j ACCEPT # SMTP SSL
iptables -A inet-local -p tcp --sport 465 -j ACCEPT # SMTP SSL
#
# 2 POP:
iptables -A local-inet -p tcp --dport 110 -j ACCEPT # POP
iptables -A inet-local -p tcp --sport 110 -j ACCEPT # POP
iptables -A local-inet -p tcp --dport 995 -j ACCEPT # POP3S (POP3 over SSL)
iptables -A inet-local -p tcp --sport 995 -j ACCEPT # POP3S (POP3 over SSL)
#
# 3 IMAP:
iptables -A local-inet -p tcp --dport 143 -j ACCEPT # IMAP
iptables -A inet-local -p tcp --sport 143 -j ACCEPT # IMAP
iptables -A local-inet -p tcp --dport 993 -j ACCEPT # IMAP SSL
iptables -A inet-local -p tcp --sport 993 -j ACCEPT # IMAP SSL
#
# REDIRECTIONS: Tout trafic ssh vient d'Internet doit être redirigé vers le SRV_SFT en dmz
iptables -t nat -A PREROUTING -j DNAT -i ${INT_EXT} -p tcp --dport $P_SSH --to-destination $SRV_SFTP
# Toutes les adresses à destination d'Internet doivent être traduites (NAT/PAT)
iptables -t nat -A POSTROUTING -o ${INT_EXT} -j MASQUERADE
