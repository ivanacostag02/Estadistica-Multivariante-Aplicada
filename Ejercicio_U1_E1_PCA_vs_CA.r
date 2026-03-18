# ============================================
# EJERCICIO 1: COMPARACIÓN VISUAL PCA VS CA
# Datos dune (vegan) - Comunidad de plantas
# ============================================

# Cargar paquetes necesarios
library(vegan)    # Funciones de ecología multivariante
library(ggplot2)  # Gráficos

# ------------------------------------------------
# 0. Cargar datos de ejemplo
# ------------------------------------------------
data(dune)      # Matriz de abundancia de especies (sitios x especies)
data(dune.env)  # Datos ambientales de los sitios

# Mirar rápidamente las primeras filas (para los alumnos)
head(dune)
head(dune.env)

# ------------------------------------------------
# 1. PCA (Análisis de Componentes Principales)
# ------------------------------------------------
# Idea para los alumnos:
# - El PCA es un método de ORDENACIÓN LINEAL.
# - Supone que las respuestas de abundancia de las especies
#   a los gradientes ambientales son aproximadamente lineales.
# - Para datos de abundancia con muchos ceros se recomienda
#   transformar previamente con Hellinger.

# Transformación de Hellinger
dune_hell <- decostand(dune, method = "hellinger")

# PCA usando rda() sin matriz ambiental (X)
pca_result <- rda(dune_hell)

# Resumen numérico del PCA
summary(pca_result)

# Comentario para alumnos:
# - 'Eigenvalues' = varianza explicada por cada componente.
# - 'Proportion Explained' = proporción de varianza de la matriz
#   de abundancias (transformadas) explicada por cada eje.
# - En estos datos, PC1 ≈ 30.6 % y PC2 ≈ 20.0 %, es decir,
#   los dos primeros ejes resumen ~50 % de la variación total.

# Extraer scores (coordenadas) de los sitios
pca_scores <- scores(pca_result, display = "sites", choices = c(1, 2))

# Data frame para ggplot
pca_df <- data.frame(
  PC1 = pca_scores[, 1],
  PC2 = pca_scores[, 2],
  Management = dune.env$Management
)

# Gráfico PCA
ggplot(pca_df, aes(x = PC1, y = PC2, color = Management)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "PCA - Ordenación Lineal",
       x = "PC1 (Componente Principal 1)",
       y = "PC2 (Componente Principal 2)")

# Comentarios para discutir con los alumnos:
# - Los puntos representan sitios, coloreados por tipo de manejo (Management).
# - Se observan agrupaciones: por ejemplo, ciertos tipos de manejo
#   tienden a ocupar zonas similares del plano PC1–PC2.
# - Esto indica que el manejo está asociado con diferencias
#   en la composición de especies.
# - Como el PCA parte de datos Hellinger, la interpretación es lineal:
#   distancias en el gráfico reflejan diferencias en abundancia relativa
#   entre sitios de forma aproximadamente euclídea.


# ------------------------------------------------
# 2. CA (Análisis de Correspondencia)
# ------------------------------------------------
# Idea para los alumnos:

# - El CA es un método de ORDENACIÓN UNIMODAL.

# - Se basa en la distancia chi-cuadrado y es apropiado
#   cuando se espera que las especies respondan de forma
#   unimodal (tipo "campana") a gradientes largos.

# - Aquí usamos los conteos originales (sin transformación).

ca_result <- cca(dune)

# Resumen numérico del CA
summary(ca_result)

# Comentario para alumnos:

# - 'Eigenvalues' = inercia (varianza chi-cuadrado) explicada.
# - 'Proportion Explained' indica qué fracción de la inercia total
#   representa cada eje.
# - En estos datos, CA1 ≈ 25.3 % y CA2 ≈ 18.9 %;
#   juntos explican ~44 % de la inercia total, algo menos que el PCA,
#   pero aún resumen gran parte del gradiente principal de composición.

# Extraer scores de sitios
ca_scores <- scores(ca_result, display = "sites", choices = c(1, 2))

# Data frame para ggplot
ca_df <- data.frame(
  CA1 = ca_scores[, 1],
  CA2 = ca_scores[, 2],
  Management = dune.env$Management
)

# Gráfico CA
ggplot(ca_df, aes(x = CA1, y = CA2, color = Management)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "CA - Ordenación Unimodal",
       x = "CA1 (Eje de Correspondencia 1)",
       y = "CA2 (Eje de Correspondencia 2)")

# Comentarios didácticos:

# - Nuevamente, los sitios se agrupan según el tipo de manejo.
# - En comparación con el PCA, el CA suele “estirar” más el gradiente:
#   los sitios extremos aparecen más alejados.
# - Esto puede ayudar a visualizar diferencias fuertes en composición
#   entre tipos de manejo (p.ej. sitios muy distintos en especies).


# ------------------------------------------------
# 3. Comparar varianza / inercia explicada
# ------------------------------------------------

cat("\nVarianza explicada por PCA (primeros 2 ejes, %):\n")
(pca_var <- eigenvals(pca_result)[1:2] / sum(eigenvals(pca_result)) * 100)

cat("\nInercia explicada por CA (primeros 2 ejes, %):\n")
(ca_var <- eigenvals(ca_result)[1:2] / sum(eigenvals(ca_result)) * 100)

# Comentarios para interpretación:
# - En este ejemplo:

#     PC1 ~ 30.6 %,  PC2 ~ 20.0 %  -> ~50.5 % en los dos primeros ejes.
#     CA1 ~ 25.3 %,  CA2 ~ 18.9 %  -> ~44.3 % en los dos primeros ejes.

# - Ambos métodos concentran una fracción similar de la información
#   en los dos primeros ejes, con ligera ventaja para el PCA.
# - Esto sugiere que, para estos datos, un modelo lineal (PCA sobre
#   Hellinger) describe bastante bien los gradientes de abundancia.

# ------------------------------------------------
# 4. Conclusiones para los estudiantes
# ------------------------------------------------
# - Tanto PCA (con transformación Hellinger) como CA revelan patrones
#   coherentes de agrupación de los sitios según el tipo de manejo.
# - El PCA explica algo más de varianza en sus dos primeros ejes y
#   produce una ordenación más “compacta”.
# - El CA, trabajando con abundancias originales y distancia
#   chi-cuadrado, enfatiza las diferencias en composición a lo largo
#   de gradientes más largos.
# - En la práctica, para datos de abundancia transformados con
#   Hellinger, suele preferirse el PCA (o RDA) como análisis principal,
#   usando el CA como análisis complementario para comprobar la
#   robustez de los patrones.
# - Este ejercicio muestra que la elección del método depende
#   tanto del supuesto ecológico (lineal vs. unimodal) como de la
#   naturaleza de los datos y de la pregunta de investigación.
