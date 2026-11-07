# Devoir 1 – Conteneurisation de Travelo : commandes (PowerShell)

Prérequis : Docker Desktop lancé, Docker Hub connecté (`docker login`), terminal dans `travelo-app/`.

```powershell
$env:DOCKER_USER = "tnorah"   # seule valeur à renseigner
```

## Volet 1

### 1. Réseau
```powershell
docker network create --driver bridge --subnet 172.18.0.0/16 travelo_net
# --driver bridge : réseau local à un hôte, DNS interne par nom de conteneur
# --subnet        : plage IP maîtrisée
```

### 2. MySQL (volume nommé)
```powershell
docker volume create travelo_mysql_data
docker run -d --name travelo-database `
  --network travelo_net `
  -e MYSQL_ROOT_PASSWORD=chaima2003 -e MYSQL_DATABASE=travelo_db `
  -v travelo_mysql_data:/var/lib/mysql `
  --restart unless-stopped `
  mysql:8.4
# -d : arrière-plan | --name : nom = hostname DNS sur le réseau
# --network : rattache au réseau | -e : variables d'init MySQL
# -v volume nommé : géré par Docker, portable, performant, sauvegardable ; un bind mount dépend du chemin Windows
#    (permissions/lenteur) et un volume anonyme est difficile à retrouver
# --restart unless-stopped : redémarre après crash/reboot
```
Preuve de persistance : `docker rm -f travelo-database`, relancer la même commande, les données sont toujours là.

Le nom `travelo-database` correspond à l'hôte attendu par `application.properties` (variable `DB_HOST`).

### 3-4. Dockerfiles et bonnes pratiques
Fichiers : `travelo_backend/Dockerfile`, `travelo_frontend/Dockerfile`, et les `.dockerignore`.

| Bonne pratique | Explication |
|---|---|
| Multi-stage build | Maven/JDK (ou Node) uniquement dans l'étape de build ; l'image finale ne contient que JRE + jar (ou Nginx + fichiers statiques) : image plus petite, surface d'attaque réduite |
| Images de base officielles, versions fixées (`mysql:8.4`, `node:22-alpine`, `eclipse-temurin:23-jre-alpine`) | Build reproductible, pas de `latest` ; variantes Alpine légères |
| JRE au lieu de JDK à l'exécution | Compilateur et outils inutiles à l'exécution |
| Cache des couches | `pom.xml` / `package*.json` copiés avant le code : les dépendances ne sont retéléchargées que si elles changent |
| `.dockerignore` | Exclut `target`, `node_modules`, `.git` : contexte de build léger, pas de fuite de fichiers |
| Utilisateur non-root | `USER spring` (backend) et image `nginx-unprivileged` (frontend) : limite l'impact d'une compromission |
| `npm ci` | Installation exacte depuis `package-lock.json` |
| `HEALTHCHECK` | Docker/Swarm détectent un service non fonctionnel et le redémarrent |
| Configuration par variables d'environnement | `DB_HOST`, `DB_PASSWORD`, `APP_CORS_ALLOWED_ORIGINS`, build-arg `REACT_APP_API_URL` : même image pour dev/test/prod, aucun secret dans l'image |
| `exec java …` (forme exec) | Java est PID 1 et reçoit SIGTERM : arrêt propre |
| `-XX:MaxRAMPercentage=75` | La JVM respecte la limite mémoire du conteneur |
| `EXPOSE` | Documente le port |
| `-DskipTests` / `dependency:go-offline` | Build rapide et dépendances en cache |

### 5. Backend : build, scan, push, run, inspect, logs
```powershell
docker build -t $env:DOCKER_USER/travelo-backend:1.0 ./travelo_backend
# -t nom:tag | ./travelo_backend : contexte de build (contient le Dockerfile)

docker scout cves $env:DOCKER_USER/travelo-backend:1.0
# Alternative : docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --severity HIGH,CRITICAL $env:DOCKER_USER/travelo-backend:1.0
# Si des failles HIGH/CRITICAL existent : mettre à jour l'image de base (rebuild avec --pull), changer de tag
# de base, ou mettre à jour la dépendance fautive dans le pom.xml, puis rescanner.
docker build --pull --no-cache -t $env:DOCKER_USER/travelo-backend:1.0 ./travelo_backend
# --pull : récupère la dernière version de l'image de base | --no-cache : ignore le cache

docker push $env:DOCKER_USER/travelo-backend:1.0

docker run -d --name travelo-backend --network travelo_net -p 8080:8080 `
  -e DB_HOST=travelo-database -e DB_PASSWORD=chaima2003 `
  -e APP_CORS_ALLOWED_ORIGINS=http://localhost:3000 `
  $env:DOCKER_USER/travelo-backend:1.0
# -p hôte:conteneur | -e : configuration (hôte DB, mot de passe, origine CORS autorisée)

docker inspect travelo-backend
# Utile : docker inspect -f "{{.NetworkSettings.Networks.travelo_net.IPAddress}}" travelo-backend
docker logs -f --tail 100 travelo-backend
# -f : suivi en continu | --tail 100 : 100 dernières lignes
```

### 6. Frontend
```powershell
docker build -t $env:DOCKER_USER/travelo-frontend:1.0 --build-arg REACT_APP_API_URL=http://localhost:8080 ./travelo_frontend
# --build-arg : URL de l'API compilée dans le bundle React (appelée par le navigateur)
docker scout cves $env:DOCKER_USER/travelo-frontend:1.0
docker push $env:DOCKER_USER/travelo-frontend:1.0
docker run -d --name travelo-frontend --network travelo_net -p 3000:3000 $env:DOCKER_USER/travelo-frontend:1.0
docker inspect travelo-frontend
docker logs -f --tail 100 travelo-frontend
```

### 7. Vérification
Ouvrir http://localhost:3000, rechercher un vol, réserver un siège (captures d'écran). API : http://localhost:8080/api/hello

### 8. Suppression des 3 conteneurs
```powershell
docker rm -f travelo-frontend travelo-backend travelo-database
# -f : arrête puis supprime
```

### 9. Docker Compose (fichier `docker-compose.yml` à la racine)
```powershell
$env:REGISTRY = ""     # images construites localement
docker compose up -d --build
docker compose ps
# up -d : crée/démarre en arrière-plan | --build : reconstruit les images
```
Vérifier http://localhost:3000 (captures).

### 10. Nettoyage
```powershell
docker compose down
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -q)
```

### 11. Registre privé + UI
```powershell
docker run -d --name registry -p 5000:5000 -v registry_data:/var/lib/registry --restart unless-stopped registry:2
docker run -d --name registry-ui -p 8081:80 -e REGISTRY_URL=http://host.docker.internal:5000 -e DELETE_IMAGES=true -e SINGLE_REGISTRY=true joxit/docker-registry-ui:latest
# UI : http://localhost:8081
docker build -t localhost:5000/travelo-backend:1.0 ./travelo_backend
docker build -t localhost:5000/travelo-frontend:1.0 --build-arg REACT_APP_API_URL=http://localhost:8080 ./travelo_frontend
docker push localhost:5000/travelo-backend:1.0
docker push localhost:5000/travelo-frontend:1.0
curl http://localhost:5000/v2/_catalog
```
`localhost:5000` est accepté par Docker sans HTTPS. Si le navigateur bloque l'UI (CORS), ajouter `-e CATALOG_ELEMENTS_LIMIT=100` ou configurer l'en-tête CORS du registre.

### 12. Compose depuis le registre privé
```powershell
docker compose down
docker rmi localhost:5000/travelo-backend:1.0 localhost:5000/travelo-frontend:1.0   # forcer le pull
$env:REGISTRY = "localhost:5000/"
docker compose pull
docker compose up -d --no-build
```
Vérifier http://localhost:3000 (captures) et l'UI du registre.

## Volet 2 – Docker Swarm

```powershell
docker compose down
docker swarm init                       # ajouter --advertise-addr <IP> si plusieurs interfaces
docker build -t localhost:5000/travelo-frontend:1.0 --build-arg REACT_APP_API_URL=http://backend.exam.local ./travelo_frontend
docker push localhost:5000/travelo-frontend:1.0
docker stack deploy -c swarm/docker-stack.yml travelo
docker stack services travelo
docker service ps travelo_travelo-backend
```
Le frontend de la stack utilise `http://backend.exam.local` : ajouter dans `C:\Windows\System32\drivers\etc\hosts` (administrateur) :
```
127.0.0.1 frontend.exam.local backend.exam.local
```
Accès : http://frontend.exam.local (captures). Test du proxy : `curl http://backend.exam.local/api/hello`.

Points de la stack : `replicas: 2`, `deploy.resources.limits`, `restart_policy`, réseau overlay `travelo_overlay`, Nginx en reverse proxy avec routage par nom de domaine (HTTP) et proxy TCP (stream) pour MySQL sur 3306.

Tests Swarm à capturer : `docker service scale travelo_travelo-backend=3`, puis `docker rm -f <un conteneur backend>` et observer la recréation avec `docker service ps`.

**Attention (replicas MySQL)** : le sujet impose 2 réplicas de la base, mais deux instances MySQL ne se répliquent pas entre elles : chacune a son propre volume, et le proxy répartit les connexions entre deux bases différentes. Pour la démonstration c'est conforme à l'énoncé ; à mentionner dans le rapport comme limite, avec la solution réelle (réplication MySQL primaire/réplica, InnoDB Cluster, ou une base managée).
