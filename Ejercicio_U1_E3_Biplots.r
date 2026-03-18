# ============================================
# EJERCICIO 3: BIPLOTS E INTERPRETACIÓN
# ============================================

library(vegan)
library(ggplot2)
library(ggrepel) # Para etiquetas no superpuestas
library(dplyr)

# Cargar datos
data(dune)
data(dune.env)

# 1. EJECUTAR DCA
dca_result <- decorana(dune)

# 2. EXTRAER SCORES
# Scores de sitios
site_scores <- scores(dca_result, display = "sites", choices = c(1, 2))
site_df <- data.frame(
  DCA1 = site_scores[, 1],
  DCA2 = site_scores[, 2],
  Site = rownames(site_scores),
  Management = dune.env$Management,
  Moisture = dune.env$Moisture
)

# Scores de especies
species_scores <- scores(dca_result, display = "species", choices = c(1, 2))
species_df <- data.frame(
  DCA1 = species_scores[, 1],
  DCA2 = species_scores[, 2],
  Species = rownames(species_scores)
)

# 3. BIPLOT BÁSICO (SITIOS SOLAMENTE)
p1 <- ggplot(site_df, aes(x = DCA1, y = DCA2, color = Management)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "DCA Biplot: Sitios por Tipo de Manejo", x = "DCA Axis 1", y = "DCA Axis 2")
print(p1)

# 4. BIPLOT CON SITIOS Y ESPECIES
p2 <- ggplot() +
  geom_point(data = site_df, aes(x = DCA1, y = DCA2, color = Management), size = 3, alpha = 0.7) +
  geom_point(data = species_df, aes(x = DCA1, y = DCA2), shape = 3, color = "red", size = 2) +
  geom_text_repel(data = species_df[1:10, ], aes(x = DCA1, y = DCA2, label = Species), size = 3, color = "darkred") +
  theme_minimal() +
  labs(title = "DCA Biplot: Sitios y Especies")
print(p2)

# 5. AÑADIR VECTORES AMBIENTALES (envfit)
env_continuous <- dune.env[, "A1", drop = FALSE]
env_fit <- envfit(dca_result, env_continuous, permutations = 999)
print(env_fit)

env_coords <- as.data.frame(scores(env_fit, "vectors"))
env_coords$Variable <- rownames(env_coords)
env_coords$DCA1 <- env_coords$DCA1 * 2
env_coords$DCA2 <- env_coords$DCA2 * 2

# 6. BIPLOT COMPLETO (TRIPLOT)
p3 <- ggplot() +
  geom_point(data = site_df, aes(x = DCA1, y = DCA2, color = Management), size = 3, alpha = 0.7) +
  geom_point(data = species_df, aes(x = DCA1, y = DCA2), shape = 3, color = "red", size = 1.5, alpha = 0.5) +
  geom_segment(data = env_coords, aes(x = 0, y = 0, xend = DCA1, yend = DCA2), arrow = arrow(length = unit(0.3, "cm")), color = "blue", linewidth = 1) +
  geom_text(data = env_coords, aes(x = DCA1, y = DCA2, label = Variable), color = "blue", fontface = "bold", vjust = -0.5) +
  theme_minimal() +
  labs(title = "DCA Triplot: Sitios + Especies + Variables Ambientales")
print(p3)

# 7. ANÁLISIS DE AGRUPAMIENTOS
centroids <- site_df %>%
  group_by(Management) %>%
  summarise(DCA1_mean = mean(DCA1), DCA2_mean = mean(DCA2))

p4 <- ggplot(site_df, aes(x = DCA1, y = DCA2, color = Management)) +
  geom_point(size = 3, alpha = 0.6) +
  stat_ellipse(type = "norm", level = 0.95) +
  geom_point(data = centroids, aes(x = DCA1_mean, y = DCA2_mean, color = Management), size = 5, shape = 17) +
  theme_minimal() +
  labs(title = "DCA con Elipses de Confianza por Grupo")
print(p4)
