#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_ENTRIES 5000

typedef struct {
    char key[512];
    int count;
} Data;

int comparer(const void *a, const void *b) {
    return ((Data*)b)->count - ((Data*)a)->count;
}

void ajouter_ou_incrementer(Data *tab, int *taille, const char *val) {
    for (int i = 0; i < *taille; i++) {
        if (strcmp(tab[i].key, val) == 0) {
            tab[i].count++;
            return;
        }
    }
    strcpy(tab[*taille].key, val);
    tab[*taille].count = 1;
    (*taille)++;
}

int est_statique(const char *url) {
    const char *exts[] = {".ico", ".css", ".js", ".png", ".jpg", ".jpeg", ".svg", ".woff", ".woff2"};
    for (int i = 0; i < 9; i++) {
        if (strstr(url, exts[i])) return 1;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc < 3) return 1;

    FILE *f = fopen("/var/log/nginx/access.log.1", "r");
    if (!f) return 1;

    Data ips[MAX_ENTRIES] = {0}, reqs[MAX_ENTRIES] = {0}, e404[MAX_ENTRIES] = {0};
    int n_ips = 0, n_req = 0, n_404 = 0;
    char ligne[2048], date_p[12], ip[46], url[512], status[4];

    while (fgets(ligne, sizeof(ligne), f)) {
        if (sscanf(ligne, "%s - - [%11[^:]", ip, date_p) != 2) continue;
        if (strcmp(date_p, argv[1]) < 0 || strcmp(date_p, argv[2]) > 0) continue;

        sscanf(ligne, "%*s - - [%*[^]]] \"%*s %s %*s\" %s", url, status);

        ajouter_ou_incrementer(ips, &n_ips, ip);

        if (strcmp(status, "404") == 0) {
            ajouter_ou_incrementer(e404, &n_404, url);
        } else if (!est_statique(url)) {
            ajouter_ou_incrementer(reqs, &n_req, url);
        }
    }
    fclose(f);

    qsort(ips, n_ips, sizeof(Data), comparer);
    qsort(reqs, n_req, sizeof(Data), comparer);

    printf("\n--- Toutes les IP ---\n");
    for (int i = 0; i < n_ips; i++) printf("%s : %d\n", ips[i].key, ips[i].count);

    printf("\n--- Top 10 Requetes ---\n");
    for (int i = 0; i < (n_req < 10 ? n_req : 10); i++) printf("%s : %d\n", reqs[i].key, reqs[i].count);

    printf("\n--- Erreurs 404 ---\n");
    for (int i = 0; i < n_404; i++) printf("%s\n", e404[i].key);

    return 0;
}