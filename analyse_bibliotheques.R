############ Analyse des bibliothèques ############

#map_france <- rnaturalearth::ne_states(country = "France", returnclass = "sf")
rm(list = ls()) 
cat("\014")  #Effacer la console

package <- c("tidyverse", "nngeo","chron", "readxl", "lubridate", "sf","jsonlite", "scales", "httr", "janitor", "ggrepel")
lapply(package, require, character.only = TRUE)
rm(package)

options( "digits"=2, "scipen"=100) 


 

############################## INTRODUCTIION ################################### 


### L'article du Monde clame l'idée d'un réseau de bibliothéque unique au monde, qui donne un accés à la lecture gratuit.
### https://www.lemonde.fr/idees/article/2025/05/31/le-livre-d-occasion-est-en-train-de-cannibaliser-en-silence-toute-la-chaine-du-livre_6609480_3232.html
### Point de départ intéressant pour faire un état des lieux des bibliothèques en France




############################ CHARGEMENT DES DONNEES ############################


# Il existe un dataset de 2023, basé sur un sondage
# Les salariés sont indiqués en ETP et elles semblent contenir des infos sur les populations des communes concernées
# L'amplitude horaire est exprimée en nombre d'ouverture d'heures hebdo

# Données des bibliothèques : https://www.data.gouv.fr/fr/datasets/adresses-des-bibliotheques-publiques-2/
# Lien du téléchargement :  https://www.data.gouv.fr/fr/datasets/r/e3588487-4732-4b6c-ab12-72d75d7f522f
# Je le télécharge en local pour éviter la nécessité d'une connexion internet à chaque chargement


biblio <- 
  #fromJSON("https://www.data.gouv.fr/api/1/datasets/r/e3588487-4732-4b6c-ab12-72d75d7f522f") %>% 
  fromJSON("data/adresses-des-bibliotheques-publiques.json") %>% 
  clean_names() %>% 
  tibble() %>% 
  print()



  
  

# On charge aussi les données de population par département et on uniformise les noms. 
# Toutes les données n'étant pas dispo sur data.gouv, nous devons passer par l'Insee. 

# Populations de référence 2022 
# https://www.insee.fr/fr/statistiques/8290591?sommaire=8290669#consulter
# Fichier à télécharger : https://www.insee.fr/fr/statistiques/fichier/8290591/ensemble.xlsx
# Les NA sont liées aux départements de Corse (2A / 2B) que nous excluerons de l'échantillon

pop_dep <- 
#rio::import("https://www.insee.fr/fr/statistiques/fichier/8290591/ensemble.xlsx", skip = 7, sheet = "Départements") %>% 
read_xlsx("data/2024 departements.xlsx", sheet = "Départements", skip = 7) %>%  
  clean_names() %>% 
  tibble() %>% 
  mutate(code_region = as.numeric(code_region)) %>% 
  mutate(code_dep = as.numeric(code_departement)) %>% 
  select(code_region, region = nom_de_la_region, code_dep, departement = nom_du_departement, ptot_dep = population_totale) %>% 
  filter(!is.na(code_dep) & code_dep <= 95 ) %>% 
  print()






# On charge la population des communes avec la population de 2024
# Lien Data.gov : https://www.data.gouv.fr/datasets/population-municipale-des-communes-france-entiere/

pop_com <- 
  #fromJSON("https://tabular-api.data.gouv.fr/api/resources/630e7917-02db-4838-8856-09235719551c/data/json/") %>% 
  fromJSON("data/2024 communes.json") %>% 
  clean_names() %>% 
  tibble() %>% 
  select(code_region = reg, code_dep = dep, insee = codgeo,pop_21_com = p21_pop, nom_com = libgeo) %>% 
  print()






# On charge les données géographiques des communes issues de datagov
# lien : https://www.data.gouv.fr/fr/datasets/decoupage-administratif-communal-francais-issu-d-openstreetmap/
# Et on rajoute la population 2021 des communes

geo_com <- 
  read_sf("data/communes-20220101-shp/communes-20220101.shp") %>% 
  mutate(dep = str_extract(insee, "^..")) %>% 
  filter(!str_detect(dep, "[:alpha:]")) %>% 
  filter(dep < 96) %>% 
  select(-wikipedia) %>% 
  rename(code_dep = dep) %>% 
  left_join(pop_com %>% select(insee, pop_21_com, code_region), join_by(insee)) %>% 
  relocate(geometry, .after = last_col()) %>% 
  print()





# Et on charge les données spaciales des départements
# lien ---- > "https://www.data.gouv.fr/fr/datasets/r/90b9341a-e1f7-4d75-a73c-bbc010c7feeb"
# On y ajoute aussi les r?gions et la population des départements

geo_dep <- 
  read_sf("data/contour-des-departements.geojson") %>% 
  mutate(code_dep = as.numeric(code)) %>% 
  filter(!is.na(code_dep)) %>% 
  select(-code) %>% 
  left_join(pop_dep %>% select(code_dep, code_region, ptot_dep), join_by(code_dep)) %>% 
  relocate(geometry , .after = last_col()) %>% 
  print()

############################ FIN DE CHARGEMENT DES DONNEES ############################












############################ NETTOYAGE DES DONNEES ############################


# on explore un peu les données 

biblio %>% 
  glimpse()

biblio %>% 
  count(type_adresse)

biblio %>% 
  summary()

biblio %>% 
  colnames()



# Nous allons nous concentrer sur la France métropolitaine et uniquement
# avec les bibliothèques "ouvertes", avec des horaires renseignés et des salariés

biblio_v1 <- 
  biblio %>% 
  filter(type_adresse == "Bâtiment ouvert") %>% 
  filter(!is.na(surface)) %>% 
  mutate(code_departement = as.numeric(code_departement)) %>% 
  filter(!is.na(code_departement)) %>% 
  filter(code_departement < 100) %>% 
  filter(!is.na(amplitude_horaire)) %>% 
  print()





# Nous cherchons maintenant à savoir si la population communales exprimée est très
# différente de notre dataset de l'insee 

biblio_v1 %>% 
  select(code_insee_commune, population_commune, ville) %>% 
  left_join(pop_com, join_by(code_insee_commune == insee)) %>% 
  mutate(ecart = population_commune - pop_21_com) %>% 
  select(ecart) %>% 
  summary()




# Même si la médiane est de 20, nous avons quelques valeurs extrêmes
#  trop importantes pour conserver les données du dataset. Nous les remplaçons
#  par celles de l'insee, sauf si elles sont en NA


# Et comme nous disposons des latitudes et longitudes, nous les transformons afin de pouvoir les localiser

biblio_def <- 
  biblio_v1 %>% 
  left_join(pop_com %>% select(insee, pop_21_com, nom_com), join_by(code_insee_commune == insee)) %>% 
  mutate(pop_commune_2021 = if_else(is.na(pop_21_com), population_commune, pop_21_com)) %>% 
  mutate(longitude = as.numeric(longitude),
         latitude = as.numeric(latitude)) %>%   
  filter(!is.na(latitude)) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs=4326) %>% 
  select(-c(pop_21_com, pop_commune_2021)) %>% 
  left_join(pop_dep %>% select(code_dep, ptot_dep), join_by(code_departement == code_dep)) %>% 
  mutate(surface = if_else(surface == 0, NA, surface),
         amplitude_horaire = if_else(amplitude_horaire == 0, NA, amplitude_horaire)) %>% 
  print()





# Nous pouvons maintenant préparer 2 datasets spécifiques : un pour la région 
# et un autre pour les départements

# Pour la région : 

biblio_def_region <- 
    biblio_def %>% 
    group_by(code_region, region) %>% 
    summarise(surf = mean(surface, na.rm = T),
              bene = mean(nombre_de_benevoles, na.rm = T),
              salarie = mean(nombre_de_salaries, na.rm = T),
              amp_mean = mean(amplitude_horaire, na.rm = T),
              amp_mediane = median(amplitude_horaire, na.rm = T),
              nb_biblio_region = n()) %>% 
    ungroup() %>% 
    mutate(region = fct_reorder(region, amp_mean) %>% fct_rev()) %>% 
    print()
  






biblio_def_dep <- 
  biblio_def %>% 
  group_by(code_departement, departement) %>% 
  summarise(surf = mean(surface, na.rm = T),
            bene = mean(nombre_de_benevoles, na.rm = T),
            salarie = mean(nombre_de_salaries, na.rm = T),
            amp_mean = mean(amplitude_horaire, na.rm = T),
            amp_mediane = median(amplitude_horaire, na.rm = T),
            nb_biblio_region = n()) %>% 
  ungroup() %>% 
  mutate(departement = fct_reorder(departement, amp_mean) %>% fct_rev()) %>% 
  print()






######################## FIN DE NETTOYAGE DES DONNEES #########################










########################## ANALYSE DES DONNEES #################################






######################## CREATION DE GRAPHIQUES ################################


### ANALYSE REPARTITION DES BIBLIOTHEQUES SUR LE TERRITOIRE



# Où sont situées les bibliothèques en France ?


biblio_def %>% colnames()


ggplot(data = biblio_def) +
  geom_sf(alpha = 0.4, aes(color = departement), show.legend = F) +
  geom_sf(data = geo_dep, lwd = 0.6, color = "gray20", alpha = 0) +
  theme_void() +
  labs(title = "Répartition des bibliothèques et médiathèques en France métropolitaine, en 2023",
       subtitle = "Chaque couleur représente un département",
       caption = "Source : data.gouv.fr, basé sur une enquête 2023 du ministère de la Culture.") +
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust =0.5),
        plot.caption = element_text(size = 10),
        plot.background = element_rect(linewidth = 1.3, fill = NA),
        plot.margin = unit(c(0.5,0.5,0.5,0.5), "cm"))
  




# Où sont les communes les plus éloignées d'une bibliothèques 


# On commence par prendre le point central de chaque commune 

communes_centroid <- 
  st_centroid(geo_com) %>% 
  print()


# Puis avec st_nn, on regarde la distance entre le centroid de chaque commune et 
# le point sur plus proche point du dataset 
# Attention, le calcul peut prendre plusieurs minutes


distance_commune_biblio <-
  st_nn(communes_centroid %>%
          select(insee), biblio_def, k = 1, returnDist = T, progress = TRUE) %>% 
  print()


# Le résultat étant sous forme de liste, 
# On extrait ensuite, la distance la plus proche de chaque commune

nearest_idx <- map_int(distance_commune_biblio$nn, 1)
nearest_dist <- map_dbl(distance_commune_biblio$dist, 1)


# Puis on associe à chaque commune la bibliothèque et la distance la plus proche
distances_plus_proche <- 
communes_centroid %>%
  st_drop_geometry() %>%
  mutate(
    id_bib_proche = biblio_def$code_bib[nearest_idx],
    dist_min_m = nearest_dist
  ) %>% 
  left_join(biblio_def, by =join_by(id_bib_proche == code_bib)) %>% 
  select(insee, nom, id_bib_proche, nom_de_l_etablissement, dist_min_m) %>% 
  mutate(dist_min_km = dist_min_m/1000) %>% 
  arrange(desc(dist_min_m)) %>% 
  print()


# Puis on la réinjecte dans la géographie des communes
geo_com_proximite <- 
  geo_com %>% 
  left_join(distances_plus_proche, by = "insee") %>% 
  print()


# On identifie aussi la commune la plus éloignée de France
commune_eloignee <- 
  geo_com_proximite %>% 
  arrange(desc(dist_min_m)) %>% 
  slice(1) %>% 
  print()
  


#Enfin, on trace notre carte

ggplot(data = geo_com_proximite) +
  geom_sf(aes(fill = dist_min_m), color = NA) +
  geom_sf(data = commune_eloignee, fill = "red")  +
  
  geom_label_repel(
    data = commune_eloignee,
    aes(geometry = geometry, label = nom.x),
    stat = "sf_coordinates",   
    nudge_x = -2,           
    nudge_y = -0.5,         
    color = "red",
    fill = "white",
    size = 4.5) +
  
  scale_fill_gradientn(
    colors = c("#2ca25f", "#fee08b", "#f03b20"),
    limits = c(0, max(geo_com_proximite$dist_min_m)), 
    breaks = seq(0, max(geo_com_proximite$dist_min_m), by = 5000),
    labels = scales::comma,
    name = "Distance en mètres, à vol d'oiseau") +
  
  theme_void() +
  
  labs(
    title = "Proximité de chaque commune à la bibliothèques la plus proche",
    subtitle = "Vert = proche, Rouge = éloigné",
    caption = "Données 2023 \n@Quentin_DataViz") +
  
  theme(plot.title = element_text(size = 14, hjust = 0.7),
        plot.subtitle = element_text(size = 12, hjust =0.7),
        plot.caption = element_text(size = 10),
        plot.background = element_rect(linewidth = 1.1, fill = NA),
        plot.margin = unit(c(0.5,0.5,0.5,0.5), "cm"),
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 8),
        legend.key.height = unit(1.2, "cm"))






# Nous pouvons également regarder quelle quantité de population sont concernées par la distance

# On compte le nombre d'habitants correspondants par tranche de 1000 mètres


labels <- paste0(seq(0, max(geo_com_proximite$dist_min_m), by = 1000)/1000, "–",
                 seq(1, max(geo_com_proximite$dist_min_m)/1000 + 1, by = 1), " km")


communes_bins <- 
geo_com_proximite %>% 
  st_drop_geometry() %>% 
  mutate(dist_bin = cut(dist_min_m,
                        breaks = seq(0, max(dist_min_m)+1000, by = 1000),
                        include.lowest = TRUE, right = FALSE,
                        labels = labels)) %>% 
  group_by(dist_bin) %>%
  summarize(
    n_communes = n(),              # nombre de communes dans le bin
    habitants = sum(pop_21_com, na.rm = TRUE)) %>%   # nombre d’habitants 
ungroup() %>% 
  mutate(total_pop = sum(habitants),
         part = round(cumsum(habitants)/total_pop,2)) %>% 
    print()


# On peut maintenant représenter la répartition des communes 
# et la part de la population pour chaque tranche de distance
 

ggplot(communes_bins, aes(x = dist_bin, y = n_communes)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      geom_text(aes(label = scales::percent(part)), 
                vjust = -0.5, 
                size = 4) +  # labels au-dessus des barres
      labs(
        title = "Nombre de communes concernées en fonction selon la distance à la bibliothèque la plus proche",
        x = "Distance à la bibliothèque (en mètres)",
        y = "Nombre de communes"
      ) +
   
  scale_y_continuous(limits = c(0,8000), 
                     n.breaks = 8,
                     labels = scales::label_number()) +
  
      theme_minimal() +
   theme(plot.title = element_text(size = 14, hjust = 0.5),
         plot.subtitle = element_text(size = 12, hjust =0.5),
         plot.caption = element_text(size = 10),
         plot.background = element_rect(linewidth = 1.1, fill = NA),
         plot.margin = unit(c(0.5,0.5,0.5,0.5), "cm"),
         axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
         axis.text.y = element_text(angle = 45, hjust = 1, size = 10),
         axis.title.x = element_text(size = 12),
         axis.title.y = element_text(size = 12))    
    
    
    




### ANALYSE DE L'HORAIRE D'OUVERTURE


# Boxplot des amplitudes 

biblio_def %>% 
  mutate(amplitude_horaire = as.numeric(amplitude_horaire)) %>% 
  ggplot(aes(x = amplitude_horaire)) +
  geom_boxplot(fill = "#0072B2", color = "black", outlier.color = "red", outlier.size = 1.5, linewidth = 0.65) +
  labs(title = "Boxplot des amplitudes horaires des bibliothèques") +
  scale_x_continuous(n.breaks = 15) +
  
  labs(
    title = "Amplitude horaire des bibliothèques",
    subtitle = "Distribution des heures d'ouverture hebdomadaire, en France métropolitaine",
    x = "Amplitude horaire hebdomadaire (en heures)",
    y = "",
    caption = "Source : data.gouv.fr, basé sur une enquête 2023 du ministère de la Culture.\n
    @Quentin_DataViz") +
  theme_minimal() +
  
  geom_vline(xintercept = median(biblio_def$amplitude_horaire, na.rm = TRUE),
             linetype = "solid", color = "red", linewidth = 1.2) +
  
  annotate(
    'rect',
    xmin = median(biblio_def$amplitude_horaire, na.rm = T)+1,
    xmax = 17,
    ymin = -0.02,
    ymax = 0.02,
    alpha = 0.5, 
    fill = 'grey40',
    col = 'black') +

    annotate("text", 
             x = median(biblio_def$amplitude_horaire, na.rm = T), 
             y = 0, 
             label = paste("Mediane:", median(biblio_def$amplitude_horaire, na.rm = T), "h/semaines"), 
             size = 3.6, hjust = -0.2) +
  
  theme(
    axis.text.y = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(color = "gray30", size = 14, hjust = 0.5),
    panel.border = element_rect(colour = "black", fill=NA, linewidth=1),
    panel.grid.minor = element_blank(),
    axis.title.x = element_text(margin = margin(t = .5, unit = "cm"), size = 14),
    axis.text.x = element_text(margin = margin(t = .5, unit = "cm"), size = 12) )



boxplot.stats(biblio_def$amplitude_horaire)



# Violin par région sur la répartition des amplitudes horaires

biblio_def %>% 
  mutate(region = fct_reorder(region, amplitude_horaire, .fun = median) %>% fct_rev()) %>% 
  ggplot(., aes(x = region, y = amplitude_horaire, fill = region)) +
  geom_violin(alpha = 0.8, show.legend = F) +
  geom_boxplot(width = 0.15, outlier.shape = NA, show.legend = F) +
  geom_text(data = biblio_def_region, aes(x = region, y = amp_mediane, label = amp_mediane), vjust = -0.6) +
  
  labs(x = "Région", 
       y = "Heures d'ouverture par semaine",
       title = "Répartition des volumes horaires par région",
       caption = "Source : data.gouv.fr, basé sur une enquête 2023 du ministère de la Culture.\n
    @Quentin_DataViz") +
  
  theme_minimal() +
  
  theme(
    axis.text.y = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(color = "gray30", size = 14, hjust = 0.5),
    plot.margin = unit(c(0.5,0.5,0.5,0.5), "cm"),
    panel.border = element_rect(colour = "black", fill=NA, linewidth=1),
    panel.grid.minor = element_blank(),
    axis.title.x = element_text(margin = margin(t = .5, unit = "cm"), size = 14),
    axis.text.x = element_text(margin = margin(t = .5, unit = "cm"), size = 12) )





ggplot(biblio_def, aes(x = amplitude_horaire)) +
  geom_histogram(binwidth = 2, fill = "steelblue", color = "black") +
  geom_text(stat = "bin", aes(label = ..count..), vjust = -0.5) +
  labs(x = "Heures d'ouverture par semaine",
       y = "Nombre de bibliothèques",
       title = "Distribution des volumes horaires hebdomadaires") +
  theme_minimal()




### Gestion des Ressources Humaines


# Nombre de bénévoles / salariés

# On regarde les ratios par département

biblio_def_dep_rh <- 
biblio_def %>% 
  st_drop_geometry() %>% 
  group_by(departement, code_dep = code_departement) %>% 
  summarise(nb_salaries = sum(nombre_de_salaries, na.rm = T),
            nb_benevoles = sum(nombre_de_benevoles, na.rm = T),
            n_biblio = n()) %>% 
  ungroup() %>% 
  mutate(sal_par_biblio = nb_salaries / n_biblio,
         bene_par_biblio = nb_benevoles / n_biblio,
         ratio = bene_par_biblio / sal_par_biblio) %>% 
  left_join(geo_dep, by = join_by(code_dep)) %>% 
  st_as_sf() %>% 
  print()



# On met une carte par département avec le ratio bénévoles / salariés

biblio_def_dep_rh 

ggplot(data = biblio_def_dep_rh) +
  
  geom_sf(aes(fill = ratio), color = "grey15") +
  
  scale_fill_gradientn(
    colors = c("#2ca25f", "#fee08b", "#f03b20"),
    limits = c(0, max(biblio_def_dep_rh$ratio, na.rm = T)+1), 
    breaks = seq(0, max(biblio_def_dep_rh$ratio, na.rm = T)+2, by = 2),
    labels = scales::comma,
    name = "Ratio bénévoles / salariés") +
  
  geom_label(data = biblio_def_dep_rh %>% st_centroid() %>%  
               mutate(lon = st_coordinates(st_centroid(geometry))[,1],
                      lat = st_coordinates(st_centroid(geometry))[,2]), 
    aes(x = lon, y = lat, label = round(ratio, 1))) + 
  
  labs(x = "",
       y = "",
    title = "Ratio entre les salariés et les bénévoles, par département",
    subtitle = "en France Métropolitaine, 2023",
    caption = "Lecture : Dans Les Landes, il y a en moyenne 3,4 bénévoles par salarié. 
    @Quentin_DataViz") +
  
  theme_void()  +
  
  theme(
    axis.text.y = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(color = "gray5", size = 14, hjust = 0.5),
    plot.caption = element_text(color = "gray15", size = 10, hjust = 1),
    plot.margin = unit(c(0.8,0.8,0.8,0.8), "cm"),
    panel.border = element_rect(colour = "black", fill=NA, linewidth=1),
    panel.grid.minor = element_blank(),
    legend.key.height = unit(1.1, "cm"))



  
  
  
  