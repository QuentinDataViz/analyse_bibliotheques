library(tidyverse)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(MASS)
library(viridis)
library(purrr)

# ----------------------------------------------------
# 1️⃣ Carte France métropolitaine
# ----------------------------------------------------
france <- ne_states(country = "France", returnclass = "sf") %>%
  filter(type == "Metropolitan département") %>%
  st_transform(2154)

# ----------------------------------------------------
# 2️⃣ Exemple : 13000 bibliothèques
# ----------------------------------------------------
set.seed(123)
n <- 13000
biblio <- tibble(
  lon = runif(n, -5, 8),
  lat = runif(n, 42, 51)
) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(2154)

# ----------------------------------------------------
# 3️⃣ Joindre bibliothèques aux départements
# ----------------------------------------------------
biblio_dept <- st_join(biblio, france, join = st_within)

# ----------------------------------------------------
# 4️⃣ Calculer densité restreinte par département
# ----------------------------------------------------
dens_list <- france$name %>% 
  map_dfr(function(dep_name){
    dep <- france %>% filter(name == dep_name)
    points_dep <- biblio_dept %>% filter(name == dep_name)
    
    if(nrow(points_dep) < 2) return(NULL)
    
    coords <- st_coordinates(points_dep)
    kde <- kde2d(coords[,1], coords[,2], n = 30)
    
    dens_df <- expand.grid(X = kde$x, Y = kde$y) %>%
      mutate(density = as.vector(kde$z)) %>%
      st_as_sf(coords = c("X","Y"), crs = st_crs(france))
    
    # garder uniquement les pixels à l'intérieur du département
    dens_df <- st_intersection(dens_df, dep)
    dens_df
  })

# ----------------------------------------------------
# 5️⃣ Tracer la heatmap interne par département
# ----------------------------------------------------
# dens_df : data.frame avec X, Y, density
# dep : département en sf

dens_df <- expand.grid(X = kde$x, Y = kde$y) %>%
  mutate(density = as.vector(kde$z))

# filtrer uniquement les pixels à l'intérieur du département
dens_df <- dens_df %>%
  st_as_sf(coords = c("X","Y"), crs = st_crs(dep)) %>%
  st_intersection(dep) %>%
  st_coordinates() %>% 
  as_tibble() %>%
  mutate(density = as.vector(kde$z))  # remettre la densité

# tracer avec geom_tile
ggplot() +
  geom_sf(data = dep, fill = "gray95", color = "gray70") +
  geom_tile(data = dens_df, aes(x = X, y = Y, fill = density)) +
  scale_fill_viridis_c() +
  theme_minimal()
