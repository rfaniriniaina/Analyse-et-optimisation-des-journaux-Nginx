# Analyseur de Journaux Nginx

Outils d'analyse et de visualisation des journaux d'accès Nginx, disponibles en deux versions : un script Bash (`analyzer.sh`) pour une analyse rapide en ligne de commande, et un script Python (`analyse_Nginx.py`) pour une visualisation graphique interactive.

---

## Fichiers

| Fichier | Description |
|---|---|
| `analyzer.sh` | Script Bash — analyse et export des résultats en fichiers texte |
| `analyse_Nginx.py` | Script Python — visualisation interactive avec Plotly |

---

## Prérequis

### Pour `analyzer.sh`
- Bash (Linux/macOS)
- Accès en lecture au fichier `/var/log/nginx/access.log`
- Outils standard : `awk`, `sort`, `uniq`, `grep`, `column`

### Pour `analyse_Nginx.py`
- Python 3.x
- Bibliothèques :
```bash
pip install plotly
```
- Accès en lecture au fichier `/var/log/nginx/access.log`

---

## Utilisation

### Script Bash — `analyzer.sh`

```bash
chmod +x analyzer.sh
./analyzer.sh
```

Le script vous demande de saisir une **date de début** et une **date de fin** au format `DD/Mon/YYYY` (3 tentatives max).

**Exemple :**
```
Date de début: 01/May/2026
Date de fin:   31/May/2026
```

Les résultats sont affichés dans le terminal **et** enregistrés dans des fichiers texte :

| Fichier de sortie | Contenu |
|---|---|
| `top5_IPs.txt` | Top 5 des adresses IP les plus actives |
| `frequent_IPs.txt` | IP ayant effectué au moins 10 accès |
| `top10_requetes.txt` | Top 10 des requêtes les plus fréquentes (hors fichiers statiques) |
| `error_404.txt` | Liste des URLs ayant retourné une erreur 404 |

> Chaque exécution ajoute les résultats avec un horodatage dans les fichiers existants.

---

### Script Python — `analyse_Nginx.py`

```bash
python3 analyse_Nginx.py <date_debut> <date_fin>
```

**Exemple :**
```bash
python3 analyse_Nginx.py 01/May/2026 31/May/2026
```

Une fenêtre interactive Plotly s'ouvre avec **4 graphiques** :

| Graphique | Description |
|---|---|
| Top 5 IP | Adresses IP avec le plus grand nombre d'accès |
| IP ≥ 10 accès | Toutes les IP ayant accédé au serveur au moins 10 fois |
| Top 10 Requêtes | URLs les plus appelées (fichiers statiques exclus) |
| Erreurs 404 | URLs ayant généré des erreurs 404 |

---

## Filtrage des fichiers statiques

Les deux outils excluent automatiquement les ressources statiques des analyses de requêtes :

`.ico` `.css` `.js` `.png` `.jpg` `.jpeg` `.svg` `.woff` `.woff2`

---

## Format des logs attendu

Les scripts sont conçus pour le format **Combined Log Format** de Nginx :

```
IP - - [DD/Mon/YYYY:HH:MM:SS +0000] "METHOD /url HTTP/1.1" STATUS size "referer" "user-agent"
```

---

## Bugs connus

Le fichier `analyse_Nginx.py` contient plusieurs erreurs à corriger avant utilisation :

- **Regex de date invalide** : `\y{4}` doit être remplacé par `\d{4}` dans l'expression régulière d'extraction de date.
- **Graphique IP fréquentes** : le second graphique (ligne 1, colonne 2) utilise par erreur les données du Top 5 IP au lieu de `ip_frequentes`.
- **Graphique Top 10 requêtes** : `c_req.most_common()` devrait être `c_req.most_common(10)` pour limiter à 10 résultats.
- **Graphique 404** : la boucle de construction des données 404 itère sur `top_req` au lieu de `top_404`.
- **Appel final sans arguments** : `analyser()` en fin de fichier est appelé sans arguments, ce qui lève une erreur — cette ligne est à supprimer.

---

## Structure du projet

```
.
├── analyzer.sh          # Script Bash d'analyse
├── analyse_Nginx.py     # Script Python de visualisation
├── top5_IPs.txt         # (généré) Top 5 IP
├── frequent_IPs.txt     # (généré) IP fréquentes
├── top10_requetes.txt   # (généré) Top 10 requêtes
└── error_404.txt        # (généré) Erreurs 404
```
