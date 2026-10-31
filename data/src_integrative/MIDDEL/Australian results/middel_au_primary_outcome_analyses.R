# This script replicates the data analysis for the primary outcome of
# Baker, F. A., Lee, Y.-E. C., Sousa, T. V., Stretton-Smith, P. A., Tamplin, J., 
# Sveinsdottir, V., Geretsegger, M., Wake, J. D., Assmus, J., & Gold, C. (2022). 
# Clinical effectiveness of music interventions for dementia and depression in elderly
# care (MIDDEL): Australian cohort of an international pragmatic cluster-randomised 
# controlled trial. The Lancet Healthy Longevity, 3(3), e153–e165. 
# https://doi.org/10.1016/S2666-7568(22)00027-7

# read and prepare data:
library(openxlsx)
rm(list=ls())
setwd('~/Documents/osf/middel')
data <- read.xlsx('middel_au_primary_outcome.xlsx')
data$group <- factor(data$group, levels=c('standardcare', 'gmt', 'rcs', 'gmt+rcs'))

# replicate published descriptive analyses from Table 2:
tab2 <- matrix(data = NA, nrow = 4, ncol = 12, dimnames = list(
  paste("Month", c(0,3,6,12)),
  paste(rep(c("n", "m", "sd"), 4), rep(levels(data$group), each = 3), sep=".")
))
for (i in 1:4) {
  for (j in 1:4) {
    x <- unlist(subset(data, as.numeric(group)==j, select=paste("madrs", c(0,3,6,12)[i], sep=".")))
    tab2[i, j*3-2] <- sum(!is.na(x))
    tab2[i, j*3-1] <- mean(x, na.rm=T)
    tab2[i, j*3] <- sd(x, na.rm=T)
  }
}
round(tab2[, c(4:12, 1:3)], 1)

# replicate published LME analyses from Table 2:
data.l <- reshape(data, idvar='id', direction='long', varying=c('madrs.0', 'madrs.3', 'madrs.6', 'madrs.12'))
data.l$time <- as.factor(data.l$time)
library(nlme)
lme1 <- lme(madrs ~ gmt*rcs*time, random = ~1|id|unit, na.action=na.omit, data=data.l)
(tab.lme <- summary(lme1))
tab.lme <- as.data.frame(tab.lme$tTable)
tab.lme <- transform(tab.lme, ci.l = Value - 1.96 * Std.Error,
                     ci.u = Value + 1.96 * Std.Error)
tab.lme <- cbind(tab.lme[8:10, c(1,6,7,5)],
            tab.lme[11:13, c(1,6,7,5)],
            tab.lme[14:16, c(1,6,7,5)])
dimnames(tab.lme) <- list(paste("Month", c(3,6,12)),
                          paste(rep(c("value", "ci.l", "ci.u", "p"), 3), rep(levels(data$group)[2:4], each = 4), sep="."))
tab.lme[, c(1:3, 5:7, 9:11)] <- round(tab.lme[, c(1:3, 5:7, 9:11)], 2)
tab.lme[, c(4, 8, 12)] <- round(tab.lme[, c(4, 8, 12)], 4)
tab.lme
