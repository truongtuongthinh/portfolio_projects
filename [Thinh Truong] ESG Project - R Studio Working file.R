Add data:
    file_path <- "D:/WIL2/Data - Data 2.csv"
    data <- read.csv(file_path)
    head(data)
    clean_data <- na.omit(data)

Summary:
    summary(data)

Multicollinearity:
  Correlation matrix:
    cor_matrix <- cor(data[, c("lagged_esg_score", "ln_asset1", "debt_to_asset")])
    print(cor_matrix)
  VIF:
    library(car)
    model <- lm(roa ~ lagged_esg_score + ln_asset1 + debt_to_asset, data = data)
    vif_values <- vif(model)
    print(vif_values)

Regression: pb ~ esg_score + roa + esg_score*roa + ln_asset1 + debt_to_asset
    library(plm)
  Pooled OLS:
    pdata <- pdata.frame(data, index = c("bank", "year"))
    pooled <- plm(roa ~ esg_score + lagged_esg_score + ln_asset1 + debt_to_asset, data = pdata, model = "pooling")
    summary(pooled)
  Fixed Effects:
    pdata <- pdata.frame(data, index = c("bank", "year"))
    fixed <- plm(roa ~ esg_score + lagged_esg_score + ln_asset1 + debt_to_asset, data = pdata, model = "within")
    summary(fixed)
Random Effects:
    pdata <- pdata.frame(data, index = c("bank", "year"))
    random <- plm(roa ~ esg_score + lagged_esg_score + ln_asset1 + debt_to_asset, data = pdata, model = "random")
    summary(random)

Test:
  Hausman Test (FE vs. RE, >0.05: choose RE):
    phtest(fixed, random)
    phtest(fixed, pooled)
  Poolability Test (FE vs. Pooled OLS, >0.05: choose Pooled OLS):
    poolability_test <- pFtest(fixed, pooled)
  Breusch-Godfrey Test (Autocorrelation):
    bg_test <- pbgtest(fixed)
  Breusch-Pagan Test (Heteroskedasticity):
    library(lmtest)
    library(sandwich)
    bp_test <- bptest(fixed)
    print(bp_test)
    robust_se <- coeftest(fixed, vcov = vcovHC(fixed, type = "HC1"))
    print(robust_se)
