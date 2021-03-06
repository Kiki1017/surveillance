context("Validate AR hhh4 via NE with identity W")

data("measlesWeserEms")

## fit with AR component as usual
vaccdata <- matrix(measlesWeserEms@map$vacc2.2004, byrow = TRUE,
                   nrow = nrow(measlesWeserEms), ncol = ncol(measlesWeserEms))
measlesModel <- list(
    ar = list(f = addSeason2formula(~1 + vacc2, S=2, period=52)),
    end = list(f = addSeason2formula(~1, S=1, period=52),
               offset = population(measlesWeserEms)),
    family = "NegBin1", data = list(vacc2 = vaccdata))
measlesFit <- hhh4(measlesWeserEms, measlesModel)

## now use an identity matrix as W in the NE component instead of AR
measlesFit2 <- suppressWarnings(
    update(measlesFit,
           ar = list(f = ~-1),
           ne = list(f = measlesModel$ar$f,
                     weights = diag(ncol(measlesWeserEms))),
           use.estimates = FALSE)
    )

## compare fits
test_that("AR-hhh4 agrees with using identity W in NE", {
    expect_equivalent(coef(measlesFit2), coef(measlesFit))
    expect_equivalent(measlesFit2$cov, measlesFit$cov)
    expect_equal(logLik(measlesFit2), logLik(measlesFit))
    expect_equal(fitted(measlesFit2), fitted(measlesFit))
})
