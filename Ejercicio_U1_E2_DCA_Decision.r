# ============================================
# EJERCICIO 2: DCA Y DECISIÓN LINEAL/UNIMODAL
# ============================================

library(vegan)
library(ggplot2)

# Cargar datos
data(dune)
data(dune.env)

# ============================================
# 1. EJECUTAR DCA
# ============================================
dca_result <- decorana(dune)

# Ver resultados completos
print(dca_result)

# Ver solo longitudes de gradiente
cat("\n=== LONGITUDES DE GRADIENTE (SD) ===\n")
dca_lengths <- dca_result$evals
print(dca_lengths)

# ============================================
# 2. EXTRAER LONGITUD DEL EJE 1
# ============================================
gradient_length <- dca_lengths[1]
cat("\n=== LONGITUD DEL PRIMER EJE DCA ===\n")
cat("Longitud:", round(gradient_length, 2), "SD\n")

# ============================================
# 3. APLICAR CRITERIO DE DECISIÓN
# ============================================
cat("\n=== DECISIÓN METODOLÓGICA ===\n")

if (gradient_length < 3) {
  cat("✓ Longitud < 3 SD: GRADIENTE CORTO\n")
  cat(" Recomendación: Usar métodos LINEALES\n")
  cat(" -> PCA (análisis indirecto)\n")
  cat(" -> RDA (análisis directo)\n")
} else if (gradient_length > 4) {
  cat("✓ Longitud > 4 SD: GRADIENTE LARGO\n")
  cat(" Recomendación: Usar métodos UNIMODALES\n")
  cat(" -> CA o DCA (análisis indirecto)\n")
  cat(" -> CCA (análisis directo)\n")
} else {
  cat("⚠ Longitud entre 3-4 SD: ZONA GRIS\n")
  cat(" Recomendación: PROBAR AMBOS MÉTODOS\n")
  cat(" -> Comparar PCA vs CA / RDA vs CCA\n")
}

# ============================================
# 4. EXTRAER SCORES DE SITIOS (DCA)
# ============================================
dca_scores_sites <- scores(dca_result, display = "sites", choices = c(1, 2))

# Crear dataframe con variables ambientales
dca_df <- data.frame(
  DCA1 = dca_scores_sites[, 1],
  DCA2 = dca_scores_sites[, 2],
  Management = dune.env$Management,
  Moisture = dune.env$Moisture
)

# ============================================
# 5. GRAFICAR ORDENACIÓN DCA
# ============================================
ggplot(dca_df, aes(x = DCA1, y = DCA2, color = Management, shape = Moisture)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = paste0("DCA Ordination (Gradient Length = ", round(gradient_length, 2), " SD)"),
       x = "DCA Axis 1",
       y = "DCA Axis 2")

# ============================================
# 6. RESUMEN ESTADÍSTICO
# ============================================
cat("\n=== RESUMEN ESTADÍSTICO ===\n")
cat("Total inertia:", sum(dca_result$evals[1:4]), "\n")
cat("Varianza explicada por eje 1:", round((dca_result$evals[1] / sum(dca_result$evals)) * 100, 1), "%\n")
