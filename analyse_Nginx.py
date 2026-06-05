import re
from collections import Counter
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import sys
from datetime import datetime

LOG_FILE = "/var/log//nginx/access.log"

def analyser(date_debut, date_fin):
    dt_start = datetime.strptime(date_debut, "%d/%b/%Y")
    dt_end = datetime.strptime(date_fin, "%d/%b/%Y")
    ips, requetes, erreurs_404 = [], [], []

    with open(LOG_FILE, "r") as f:
        for ligne in f:

            match = re.search(r'\[(\d{2}/\w{3}/\y{4})', ligne)
            if not match:
                continue

            log_date = datetime.strptime(match.group(1), "%d/%b/%Y")
            if not (dt_start <= log_date <= dt_end):
                continue

            cols = ligne.split()
            if len(cols) < 9:
                continue

            ip, url, status = cols[0], cols[6], cols[8]
            ips.append(ip)

            #non statique
            est_statique = re.search(r"\.(ico|css|js|png|jpg|jpeg|svg|woff|woff2)$", url)
            if not est_statique:
                requetes.append(url)

            if status == "404":
                erreurs_404.append(url)

    #calcul
    c_ips, c_req, c_404 = Counter(ips), Counter(requetes), Counter(erreurs_404)

    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=("Top % IP", "IP >= 10 acces au serveur", "Top 10 Requêtes", "Erreurs 404"),
        vertical_spacing=0.2)
    
    top_ips = c_ips.most_common(5)
    x_ips = []
    y_ips = []

    for item in top_ips:
        x_ips.append(item[0])
        y_ips.append(item[1])
    fig.add_trace(go.Bar(x=x_ips, y=y_ips), 1, 1)

    ip_frequentes = {}
    for ip, count in c_ips.items():
        if count >= 10:
            ip_frequentes[ip] = count
    fig.add_trace(go.Bar(x=x_ips, y=y_ips), 1, 1)

    for item in top_ips:
        x_ips.append(item[0])
        y_ips.append(item[1])
    fig.add_trace(go.Bar(x=list(ip_frequentes.keys()), y=list(ip_frequentes.values())), 1, 2)

    top_req = c_req.most_common()
    x_req, y_req = [], []

    for item in top_req:
        x_req.append(item[0])
        y_req.append(item[1])
    fig.add_trace(go.Bar(x=x_req, y=y_req), 2, 1)

    top_404 = c_404.most_common(5)
    x_404, y_404 = [], []

    for item in top_req:
        x_req.append(item[0])
        y_req.append(item[1])
    fig.add_trace(go.Bar(x=x_404, y=y_404), 2, 2)

    fig.update_layout(height=800, showlegend=False, title_text="Analyse des logs Nginx")
    fig.show()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("\nUsage: python3 analyse_Nginx.py <date_debut> <date_fin>")
        print("Format: 01/Jun/2026")
    else:
        analyser(sys.argv[1], sys.argv[2])
    analyser()