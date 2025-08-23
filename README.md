# BIENVENUE !

Bienvenue dans  cette analyse ! N'hésitez pas à me partager vos feedbacks
Le fichier contenant l'ensemble du code se situe dans analyse.bibliothèques.R

# 📊 Projet : Analyse du Jeu de data sur les bibliothèques en France

## 🎯 Objectifs
L'article du Monde clame l'idée d'un réseau de bibliothéque unique au monde, qui donne un accés à la lecture gratuit.
https://www.lemonde.fr/idees/article/2025/05/31/le-livre-d-occasion-est-en-train-de-cannibaliser-en-silence-toute-la-chaine-du-livre_6609480_3232.html

C'est un point de départ intéressant pour faire un état des lieux des bibliothèques en France

---

## 📂 Données
- Source : https://www.data.gouv.fr/fr/datasets/adresses-des-bibliotheques-publiques-2/  
- Format : json (10 Mo)  
- Taille du dataset : 15 882 observations et 23 variables

Au vu de la médiocre qualité des données, quelques concessions ont été faites :

- Nous analyserons que les bibliothèques ayant un statut "Bâtiment ouvert"
- les bibliothèques sans horaires d'ouvertures ni surface (ou égales à 0) ont été ignorées
- Nous nous concentrons que sur la France Métropolitaine 

Ce qui nous laisse +/- 13 000 observations pour nous amuser. 

---

## 📂 Insights 

Le maillage de bibliothèque est très dense en France. 
La quasi totalité de la population vit à moins de 20km d'une bilbiothèque (ou médiathèque ou autre point similaire).
En revanche, cette proxmité se fait au détriment des horaires d'ouvertures. 
L'amplitude médiane en France est de seulement 9 heures par semaine. 
Le réseau repose également massivement sur un volant de bénévoles, pouvant représenter parfois jusqu'à 3 fois le nombre de salariés. 

---



## 📈 Visualisations
Quelques graphiques rapides pour donner un aperçu :  

### Répartition des bibliothèques en France, en 2023





### Exemple 2 : Évolution temporelle
![Graphique séries temporelles](figures/time_series.png)


*(Les graphiques sont générés via R)*

---

## 🛠️ Code R
- Script principal : [`analyse.R`](data/analyse_bibliotheques.R)  
- Chaque fichier utilisé peut être téléchargé et dispose de son adresse de téléchargement. 

