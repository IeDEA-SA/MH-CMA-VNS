# https://cran.r-project.org/web/packages/kml/kml.pdf
# https://www.jstatsoft.org/article/view/v065i04
# file:///C:/Users/haas/AppData/Local/Temp/v65i04.pdf

## Clear
rm(list = ls())

## Package
library("manipulateWidget")
library("rgl")
library("crosstalk")
library("longitudinalData")
library("misc3d")
library("kml")
library("foreign")

## Data
cma <- read.dta("C:/Data/IeDEA/Adh/v2/clean/CMAq_wide.dta")

imputation(as.matrix(cma[, 2:21]), method = "trajMean")

cldSDQ <- cld(cma, timeInData = 2:21, maxNA = 8, varNames = "CMA")
cldSDQ

#kml(cldSDQ, nbRedraw = 2, toPlot = 'both')
kml(cldSDQ)

choice(cldSDQ)
plotAllCriterion(cldSDQ)

cma$c2 <- getClusters(cldSDQ, 2)
cma$c3 <- getClusters(cldSDQ, 3)
cma$c4 <- getClusters(cldSDQ, 4)
cma$c5 <- getClusters(cldSDQ, 5)
cma$c6 <- getClusters(cldSDQ, 6)

write.dta(cma, "C:/Data/IeDEA/Adh/v2/clean/CMAq_c.dta") 

