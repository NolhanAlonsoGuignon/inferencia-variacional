# -----------------------------------------------------------------------------
# Figuras conceptuales de la parte teórica.
#
#   figures/subestimacion-varianza.png : posterior gaussiana correlada frente a
#                                        su aproximación mean-field óptima.
#   figures/descomposicion-elbo.png    : log p(x) = ELBO + KL a lo largo de las
#                                        iteraciones de la optimización.
#
# Uso (desde la raíz del repositorio):  Rscript R/generar_figuras.R
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2)
  library(ellipse)
})

dir.create("figures", showWarnings = FALSE)

col_p <- "#1B7F5C"   # posterior exacta
col_q <- "#C2410C"   # aproximación variacional

# 1. Subestimación de la varianza -------------------------------------------
# Para una posterior p(z) = N(mu, Sigma), el factor mean-field que minimiza
# KL(q || p) es q_j(z_j) = N(mu_j, 1 / Lambda_jj), con Lambda = Sigma^{-1}.
# Como 1 / Lambda_jj <= Sigma_jj, la aproximación es siempre más estrecha.

mu    <- c(0, 0)
rho   <- 0.9
Sigma <- matrix(c(1, rho, rho, 1), 2)
Sigma_q <- diag(1 / diag(solve(Sigma)))

contornos <- function(S, nivel, dist) {
  e <- ellipse(S, centre = mu, level = nivel, npoints = 200)
  data.frame(z1 = e[, 1], z2 = e[, 2], nivel = nivel, dist = dist)
}

niveles <- c(0.5, 0.9, 0.99)
df_ell <- rbind(
  do.call(rbind, lapply(niveles, contornos, S = Sigma,   dist = "Posterior exacta p(z | x)")),
  do.call(rbind, lapply(niveles, contornos, S = Sigma_q, dist = "Aproximación mean-field q(z)"))
)
df_ell$grupo <- interaction(df_ell$dist, df_ell$nivel)

p1 <- ggplot(df_ell, aes(z1, z2, group = grupo, colour = dist)) +
  geom_path(aes(alpha = factor(nivel)), linewidth = 0.9) +
  scale_colour_manual(values = setNames(c(col_p, col_q), unique(df_ell$dist))) +
  scale_alpha_manual(values = c(1, 0.7, 0.4), guide = "none") +
  coord_equal(xlim = c(-3.2, 3.2), ylim = c(-3.2, 3.2)) +
  labs(
    x = expression(z[1]), y = expression(z[2]), colour = NULL,
    title = "Mean-field subestima la varianza",
    subtitle = sprintf("Posterior gaussiana con correlación %.1f\nVarianza marginal real = 1  |  varianza aproximada = %.2f",
                       rho, Sigma_q[1, 1])
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

ggsave("figures/subestimacion-varianza.png", p1, width = 6.5, height = 6.2, dpi = 200, bg = "white")

# 2. Descomposición log p(x) = ELBO + KL -----------------------------------
iter    <- 0:40
log_px  <- -100
kl      <- 2 + 38 * exp(-iter / 7)          # KL(q || p) decrece con la optimización
elbo    <- log_px - kl

df_elbo <- data.frame(iter, log_px, elbo)

p2 <- ggplot(df_elbo, aes(iter)) +
  geom_ribbon(aes(ymin = elbo, ymax = log_px, fill = "KL(q || p)"), alpha = 0.25) +
  geom_line(aes(y = log_px, colour = "log p(x)  (evidencia, constante)"),
            linewidth = 1.1, linetype = "dashed") +
  geom_line(aes(y = elbo, colour = "ELBO"), linewidth = 1.3) +
  scale_colour_manual(values = c("log p(x)  (evidencia, constante)" = col_p, "ELBO" = col_q)) +
  scale_fill_manual(values = c("KL(q || p)" = "#94A3B8")) +
  labs(
    x = "Iteración", y = NULL, colour = NULL, fill = NULL,
    title = "Maximizar el ELBO equivale a minimizar la KL",
    subtitle = "El hueco entre la evidencia y el ELBO es exactamente KL(q || p)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(),
        axis.text.y = element_blank())

ggsave("figures/descomposicion-elbo.png", p2, width = 7, height = 4.5, dpi = 200, bg = "white")

message("Figuras generadas en figures/")
