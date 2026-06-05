#!/bin/bash

#configuration
LOG_FILE="/var/log/nginx/access.log"
TMP_FILE="/tmp/filtre.log"
MAX_ESSAI=3
essai=0

#verification des droits d'acces
if [ ! -r "$LOG_FILE" ]; then
    echo "Erreur: Impossible de lire $LOG_FILE".
    exit 1
fi

echo -e "\n----------------------------------------------"
echo "ANALYSE ET OPTIMISATION DES JOURNAUX NGINX"
echo -e "\nFormat requis pour les dates: DD/Mon/YYYY"
echo "Formats des mois: Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec"
echo "Exemple de saisie: 06/May/2026"
echo -e "-------------------------------------------------\n"

while [ $essai -lt $MAX_ESSAI ]; do
    read -p "Date de début: " debut_date
    read -p "Date de fin: " fin_date

    if [[ "$debut_date" =~ ^[0-9]{2}/[A-Za-z]{3}/[0-9]{4} && "$fin_date" =~ ^[0-9]{2}/[A-Za-z]{3}/[0-9]{4} ]]; then
        break
    fi

    essai=$((essai + 1))
    echo "Erreur: Format invalide. Tentative $essai/$MAX_ESSAI."
done

#extraction des donnees avec conversion en minuscules
awk -v debut="$(echo "$debut_date" | tr '[:upper:]' '[:lower]')" \
    -v fin="$(echo "$fin_date" | tr '[:upper:]' '[:lower]')" '
{
    date_part = tolower(substr($4, 2, 11))
    if(date_part >= debut && date_part <= fin)
    {
        print $0
    }
}' "$LOG_FILE" > "$TMP_FILE"

#verification si le filtrage a produit des resultats
if [ ! -s "$TMP_FILE" ]; then   
    echo "Aucune donnée trouvée pour cette période."
    rm -f "$TMP_FILE"
    exit 0
fi

#ajouter une separation dans les fichiers
ecrire_resultats()
{
    echo -e "\n ---Analyse du $(date '+%d/%m/%Y %H:%M:%S')---" >> "$1"
}

echo -e "\n ---Top 05 IP ayant le plus grand nombre d'acces---"
ecrire_resultats top5_IPs.txt
awk '{print $1}' "$TMP_FILE" | sort | uniq -c | sort -nr | head -n5 | column -t | tee -a top5_IPs.txt

echo -e "\n ---IP avec au moins 10 fois acces au serveur---"
ecrire_resultats frequent_IPs.txt
awk '{print $1}' "$TMP_FILE" | sort | uniq -c | awk '$1 >= 10 {print $2}' | column -t | tee -a frequent_IPs.txt

echo -e "\n ---Top 10 requêtes les plus frequemment appelees---"
ecrire_resultats top10_requetes.txt
awk '{print $7}' "$TMP_FILE" | grep -vE "\.(ico|css|js|png|jpg|jpeg|svg|woff|woff2)$" | sort | uniq -c | sort -n | head -n10 | column -t | tee -a top10_requetes.txt

echo -e "\n ---Adresses de requêtes avec un statut 404---"
ecrire_resultats error_404.txt
awk '$9 == 404 {print $7}' "$TMP_FILE" | sort -u | tee -a error_404.txt

rm -f "$TMP_FILE"

echo -e "\n Analyse terminée. Résultats ajoutés dans: "
echo "* top5_IPs.txt"
echo "* frequent_IPs.txt"
echo "* top10_requetes.txt"
echo "* error_404.txt"
