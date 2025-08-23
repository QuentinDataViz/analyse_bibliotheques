# BIENVENUE !

Bienvenue dans  cette analyse ! N'hésitez pas à me partager vos feedbacks
Le fichier contenant l'ensemble du code se situe dans analyse.bibliothèques.R

# 📊 Projet : Analyse d'un Jeu de data sur les bibliothèques en France

## 🎯 Objectifs
L'article du Monde clame l'idée d'un réseau de bibliothèque unique au monde, qui donne un accés à la lecture gratuit.
https://www.lemonde.fr/idees/article/2025/05/31/le-livre-d-occasion-est-en-train-de-cannibaliser-en-silence-toute-la-chaine-du-livre_6609480_3232.html

C'est un point de départ intéressant pour faire un état des lieux des bibliothèques en France

---

## 📂 Données
- Source : https://www.data.gouv.fr/fr/datasets/adresses-des-bibliotheques-publiques-2/  
- Format : json (10 Mo)  
- Taille du dataset : 15 882 observations et 23 variables

Au vu de la médiocre qualité des données, quelques concessions ont été faites :

- Nous analyserons que les bibliothèques ayant un statut "Bâtiment ouvert"
- les bibliothèques sans horaires d'ouvertures ni surfaces (ou égales à 0) ont été ignorées
- Nous nous concentrons que sur la France Métropolitaine 

Ce qui nous laisse +/- 13 000 observations pour nous amuser. 

---

## 🗝️ Insights 

Le maillage de bibliothèque est très dense en France. 
La quasi totalité de la population vit à moins de 20km d'une bilbiothèque (ou médiathèque ou autre point similaire).

Cette proxmité semble se faire au détriment des horaires d'ouvertures des structures. 
L'amplitude médiane en France est de seulement 9 heures par semaine. 

Le réseau repose également massivement sur un volant de bénévoles, pouvant représenter parfois jusqu'à 3 fois le nombre de salariés. 

---

## 📈 Visualisations
Quelques graphiques rapides pour donner un aperçu :  

### Répartition des bibliothèques en France, en 2023
<img width="905" height="883" alt="image" src="https://github.com/user-attachments/assets/9bdcb804-ddcf-4fa6-a921-2a582c736660" />


### Distance des communes à la bibliothèque la plus proche
<img width="1258" height="1071" alt="image" src="https://github.com/user-attachments/assets/b64b6e71-055b-43f1-b121-a9e7f4465d00" />


### Ratio des bénévoles / salariés, par département
<img width="1028" height="896" alt="image" src="https://github.com/user-attachments/assets/abe9e90b-fd72-4b09-adc7-28441dece419" />


*(Les graphiques sont générés via R)*

---

## 🛠️ Code R
- Script principal : [`analyse.R`](analyse_bibliotheques.R)  
- Chaque fichier utilisé peut être téléchargé et dispose de son adresse de téléchargement.
- Retrouvez d'autres insights dans le script

