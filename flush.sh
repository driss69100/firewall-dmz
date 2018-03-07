#!/bin/sh
#
# Script pour vider les règles iptables
#
# Variable:
#
INT_EXT=eth0
#
# On remet la police par défaut à ACCEPT
#
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
#
# On remet les polices par défaut pour la table NAT
#
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT
#
# On vide (flush) toutes les règles existantes
#
iptables -F
iptables -t nat -F
#
# Et enfin, on efface toutes les chaînes qui n'existent
# pas par défaut dans les tables filter et nat
#
iptables -X
iptables -t nat -X
iptables -t nat -A POSTROUTING -o ${INT_EXT} -j MASQUERADE
exit 0
