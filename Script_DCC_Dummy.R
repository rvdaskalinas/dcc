library(rmgarch)
library(ggplot2)

# Prices
Mon_P <- DATA_Updated$Mon_P
Btc_P <- DATA_Updated$Btc_P

# Size check
if(length(Mon_P) != length(Btc_P)) {
  stop("Lengths of Mon_P and Btc_P are not the same")
}

# Returns
Mon_R <- diff(log(Mon_P))
Btc_R <- diff(log(Btc_P))

# Date sampling
start_date <- as.Date("2017-11-09")
dates <- seq.Date(from = start_date, by = "day", length.out = length(Mon_P))

# 3 dummies for Monero
monero_dummy_dates <- as.Date(c("2024-02-06", "2020-03-12", "2021-05-12"))
# 1 dummy for bitcoin
bitcoin_dummy_date <- as.Date("2020-03-12")

# dummy creation
dummy1 <- as.integer(dates == monero_dummy_dates[1])
dummy2 <- as.integer(dates == monero_dummy_dates[2])
dummy3 <- as.integer(dates == monero_dummy_dates[3])
dummy_btc <- as.integer(dates == bitcoin_dummy_date)

# Price Matrix
data_matrix <- cbind(Mon_P, Btc_P)

# We put the dummies into a matrix
dummy_matrix_monero <- cbind(dummy1, dummy2, dummy3)
dummy_matrix_bitcoin <- matrix(dummy_btc, ncol = 1)


# Garch for Monero with the dummies as external regressors
uspec1 <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 0), include.mean = TRUE, 
                    external.regressors = dummy_matrix_monero),
  distribution.model = "norm"
)

# Garch for Bitcoin with the dummy as an external regressor
uspec2 <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 0), include.mean = TRUE, 
                    external.regressors = dummy_matrix_bitcoin),
  distribution.model = "norm"
)

# DCC
mspec <- dccspec(
  uspec = multispec(list(uspec1, uspec2)),
  dccOrder = c(1, 1),
  distribution = "mvnorm"
)

fit <- dccfit(spec = mspec, data = data_matrix)

# Results
print(fit)
summary(fit)

# CC extraction
cond_corr <- rcor(fit)
cond_corr_df <- data.frame(Date = dates, Conditional_Correlation = cond_corr[1, 2, ])

# CC plot
ggplot(cond_corr_df, aes(x = Date, y = Conditional_Correlation)) +
  geom_line(color = "blue") +
  labs(title = "Conditional Correlations between Monero and Bitcoin",
       x = "Date",
       y = "Conditional Correlation") +
  theme_minimal()

