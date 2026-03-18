# ==========================================================
# TEMA 2.3.4. AGRUPAMIENTOS DE SITIOS Y ESPECIES
# ==========================================================

library(cluster)
library(indicspecies)   # para IndVal (especies indicadoras)

# ----------------------------------------------------------
# 1. IDENTIFICACIÓN DE CLUSTERS SOBRE LOS SCORES DCA
# ----------------------------------------------------------

# Tomamos los scores de sitios en los dos primeros ejes DCA
site_scores_mat <- as.matrix(site_df[, c("DCA1", "DCA2")])
row.names(site_scores_mat) <- site_df$Site

# 1.1 Distancias Euclidianas entre sitios (en el espacio de ordenación)
dist_sites <- dist(site_scores_mat, method = "euclidean")

# 1.2 Cluster jerárquico (método Ward)
hclust_sites <- hclust(dist_sites, method = "ward.D2")

# Dendrograma
plot(hclust_sites, labels = site_df$Management,
     main = "Dendrograma de sitios (scores DCA)",
     xlab = "Sitios (coloreados por manejo)",
     sub = "")

# Comentarios para alumnos:
# - Cada hoja del dendrograma es un sitio.
# - La altura a la que se unen los sitios indica cuán diferentes son 
#   sus composiciones florísticas (según DCA1–DCA2).
# - Sitios con el mismo tipo de manejo que se agrupan a baja altura
#   sugieren comunidades más homogéneas dentro de ese manejo.

# 1.3 Definir un número de clusters k (por ejemplo, k = 3)
k <- 3
site_clusters <- cutree(hclust_sites, k = k)
site_df$Cluster_hc <- factor(site_clusters)

# Visualizar en el plano DCA
ggplot(site_df, aes(x = DCA1, y = DCA2,
                    color = Cluster_hc, shape = Management)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = paste("Clusters jerárquicos de sitios (k =", k, ")"),
       x = "DCA1", y = "DCA2")

# Interpretación:
# - Aquí vemos las “nubes” de sitios que el algoritmo Ward define como grupos.
# - Se puede comparar con el color de Management:
#   si los clusters coinciden bastante con BF/HF/NM/SF, quiere decir que el
#   tipo de manejo captura bien la estructura de la vegetación.
# - Si aparecen clusters mixtos (varios manejos en un mismo cluster), esto
#   sugiere que hay otros gradientes (p.ej. humedad) superpuestos al manejo.

# 1.4 K-means sobre scores DCA (clustering no jerárquico)
set.seed(123)  # para reproducibilidad
km_res <- kmeans(site_scores_mat, centers = k, nstart = 50)

site_df$Cluster_km <- factor(km_res$cluster)

ggplot(site_df, aes(x = DCA1, y = DCA2,
                    color = Cluster_km, shape = Management)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = paste("Clusters k-means de sitios (k =", k, ")"),
       x = "DCA1", y = "DCA2")

# Comentario:
# - K-means busca centros de gravedad en el espacio DCA1–DCA2.
# - Los alumnos pueden comparar:
#   * Clusters jerárquicos vs k-means (consistencia de agrupamientos).
#   * Clusters vs tipos de manejo (Management) para evaluar si los grupos
#     estadísticos coinciden con los grupos de manejo definidos a priori.

# ----------------------------------------------------------
# 2. PERMANOVA: PRUEBA FORMAL ENTRE GRUPOS
# ----------------------------------------------------------

# PERMANOVA sobre matriz de especies (dune) usando Management como factor
permanova_mgmt <- adonis2(dune ~ Management, data = dune.env,
                          method = "bray", permutations = 999)
print(permanova_mgmt)

# Comentarios:
# - adonis2 entrega un pseudo-F y un valor p para la hipótesis:
#   H0: no hay diferencias en composición de especies entre tipos de manejo.
# - Si p < 0.05 → rechazamos H0: la composición difiere significativamente
#   entre los manejos (esto respalda lo observado en los biplots y clusters).
# - Esto conecta directamente con P1: “¿en qué medida Management explica
#   las diferencias en la composición de especies?”.

# (Opcional) PERMANOVA añadiendo Use
permanova_mgmt_use <- adonis2(dune ~ Management * Use, data = dune.env,
                              method = "bray", permutations = 999)
print(permanova_mgmt_use)

# Interpretación:
# - Termino Management: efecto principal del tipo de manejo.
# - Término Use: efecto principal del uso del suelo.
# - Interacción Management:Use: indica si el efecto del manejo depende
#   del tipo de uso (por ejemplo, manejo de conservación en praderas de heno
#   vs praderas pastoreadas).

# ----------------------------------------------------------
# 3. ASOCIACIONES DE ESPECIES EN EL ESPACIO DCA
# ----------------------------------------------------------

# Matriz de scores de especies
species_scores_mat <- as.matrix(species_df[, c("DCA1", "DCA2")])
row.names(species_scores_mat) <- species_df$Species

# Distancias entre especies (para ver coocurrencias vs exclusiones)
dist_species <- dist(species_scores_mat, method = "euclidean")
hclust_species <- hclust(dist_species, method = "ward.D2")

plot(hclust_species, main = "Dendrograma de especies (scores DCA)",
     xlab = "Especies", sub = "")

# Comentarios:
# - Especies que se unen a baja altura están muy próximas en DCA:
#   tienden a coocurrir y compartir nicho (requisitos ambientales similares).
# - Especies en ramas muy separadas (extremos opuestos del dendrograma)
#   se ubican en extremos distintos del biplot:
#   potenciales casos de exclusión mutua o nichos muy contrastantes.

# Ejemplo: listar las 5 especies más cercanas a una especie de interés
target_sp <- "Comapalu"
if (target_sp %in% row.names(dist_species)) {
  dist_to_target <- as.matrix(dist_species)[target_sp, ]
  closest <- sort(dist_to_target)[2:6]   # excluye la propia especie
  cat("\nEspecies más cercanas a", target_sp, "en el espacio DCA:\n")
  print(closest)
}

# ----------------------------------------------------------
# 4. ESPECIES INDICADORAS (IndVal) POR TIPO DE MANEJO
# ----------------------------------------------------------

# IndVal utilizando Management como agrupador
# (trabajamos con abundancias de dune)
mgmt_groups <- dune.env$Management

indval_res <- multipatt(dune, mgmt_groups,
                        func = "IndVal.g", control = how(nperm = 999))
summary(indval_res)

# Comentarios:
# - IndVal combina frecuencia de ocurrencia y abundancia para cada especie
#   en cada grupo de manejo.
# - El resumen muestra:
#   * Especies asociadas significativamente (p < 0.05) a cada nivel de Management.
#   * Estas son nuestras “especies indicadoras” formales, que complementan
#     la lectura visual de los biplots DCA.
# - Conecta con P2:
#   “¿Qué especies actúan como indicadoras de cada tipo de manejo…?”
#   → aquí tenemos una respuesta estadísticamente fundada.

# Extra: podemos cruzar especies indicadoras con su posición en DCA
# para ver si la interpretación visual coincide con IndVal.

# ----------------------------------------------------------
# 5. CARACTERIZACIÓN AMBIENTAL DE CLUSTERS
# ----------------------------------------------------------

# Ejemplo: comparar A1 entre clusters jerárquicos
ggplot(site_df, aes(x = Cluster_hc, y = dune.env$A1,
                    fill = Cluster_hc)) +
  geom_boxplot(alpha = 0.7) +
  theme_minimal() +
  labs(title = "Espesor de A1 por cluster de sitios (Ward sobre DCA)",
       x = "Cluster (jerárquico)", y = "A1 (espesor horizonte)")

# ANOVA simple como aproximación exploratoria
anova_A1 <- aov(dune.env$A1 ~ site_df$Cluster_hc)
summary(anova_A1)

# Comentarios:
# - Si el ANOVA (o, mejor aún, una PERMANOVA multivariante) muestra
#   diferencias significativas de A1 entre clusters, concluimos que
#   los agrupamientos reflejan también diferencias edáficas.
# - Se puede repetir el mismo enfoque con Moisture y Manure para ver si
#   hay gradientes claros de humedad y fertilización entre grupos.

# ==========================================================
# NOTA DIDÁCTICA PARA LOS ALUMNOS
# ==========================================================
cat("\n--- Resumen Tema 2.3.4 ---\n")
cat("1) Los clusters sobre los scores DCA permiten detectar grupos de\n")
cat("   sitios con composición florística similar, complementando la\n")
cat("   inspección visual del biplot.\n")
cat("2) PERMANOVA prueba formalmente si Management y Use explican\n")
cat("   diferencias significativas en composición de especies.\n")
cat("3) El dendrograma de especies y los biplots muestran asociaciones\n")
cat("   (coocurrencia) y exclusiones (nichos contrastantes) entre especies.\n")
cat("4) El análisis de especies indicadoras (IndVal) identifica qué\n")
cat("   especies caracterizan estadísticamente cada tipo de manejo.\n")
cat("5) Comparar variables ambientales entre clusters ayuda a interpretar\n")
cat("   qué gradientes (A1, humedad, fertilización) sostienen estos\n")
cat("   patrones de agrupamiento.\n")
