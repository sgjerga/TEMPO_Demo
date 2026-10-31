rm(list=ls())
library(haven)
path_data_osf <- "/Users/chgo/Documents/osf/middel/Salivary biomarkers/"
path_scripts <- path_data_osf
path_output <- '/Users/chgo/Documents/'
# read data:
load(file=paste0(path_data_osf, "middel_bio.RData"))
# end read prepared data.
# data prep for these analyses:
# remove those who didn't participate in the session:
rasing <- subset(rasing, present_sess==1)
# remove physiologically implausible outlier:
rasing$sCort[rasing$sCort > 200] <- NA
# log transform (Naomi used log10(x+1))
rasing <- transform(rasing, log.sAA = log10(sAA+1), 
                    log.sCort = log10(sCort+1),
                    log.vas_s = log10(vas_s+1))
# factors and more groups:
rasing$month <- as.factor(rasing$month)
rasing$group3 <- as_factor(rasing$group, levels="labels")
rasing$group3 <- as.character(rasing$group3)
rasing$group4 <- rasing$group3
rasing$group4[rasing$present_sess==2] <- "PASSIVE" # non-randomised comparison
rasing$group3f <- factor(rasing$group3, levels=c("GMT", "RCS", "CONTROL"))
rasing$group4f <- factor(rasing$group4, levels=c("GMT", "RCS", "CONTROL", "PASSIVE"))
# reshape to wide
rasing <- transform(rasing, time2 = paste0(month, time))
rasing.w <- reshape(rasing, v.names = c("sAA", "sCort", "vas_s", "log.sAA", "log.sCort"),
                    timevar = "time2",
                    idvar = "pid",
                    drop = c("month", "time"),
                    direction = "wide")
# end prepare and reshape.

library(psych)
# Fig. 1: line charts (median or mean) (or violin?)
library(vioplot)
xadj.times <- .35
set.seed(123)
dots <- T # change to F for omitting dots
# all original:
# pdf(paste0(path_output, "fig1 original scale.pdf"))
# par(mfrow=c(3,1), mai=c(.1,.6,.1,.1))
outcome <- "sAA"; source(paste0(path_scripts, "middel_bio_fig1.R"))
outcome <- "sCort"; source(paste0(path_scripts, "middel_bio_fig1.R"))
outcome <- "vas_s"; source(paste0(path_scripts, "middel_bio_fig1.R"))
# dev.off()
# all log:
# pdf(paste0(path_output, "fig1 log scale.pdf"))
# par(mfrow=c(3,1), mai=c(.1,.6,.1,.1))
outcome <- "log.sAA"; source(paste0(path_scripts, "middel_bio_fig1.R"))
outcome <- "log.sCort"; source(paste0(path_scripts, "middel_bio_fig1.R"))
outcome <- "log.vas_s"; source(paste0(path_scripts, "middel_bio_fig1.R"))
# dev.off()

# line plots - NOT log:
rasing.col <- c("blue", "red", "black", "grey")
xadj.times <- .35
xadj.groups <- .02
# pdf(paste0(path_output, "fig2 lines orig scale, 3 groups.pdf"))
groups <- "group3f"
# dev.off()
# 3 groups, PP, original scale:
# pdf(paste0(path_output, "fig2 lines orig scale, 3 groups PP.pdf"), width=8)
# sink(paste0(path_output, "descriptives and tests.txt"))
groups <- "group4f"
par(mfrow=c(1,1))
outcome <- "sCort"; outcome.lab <- "Salivary cortisol (nmol/l)"; ylim <- c(0, 28) # >100 is implausible
source(paste0(path_scripts, "middel_bio_fig2.R"))
outcome <- "sAA"; outcome.lab <- "Salivary alpha-amylase (U/ml)"; ylim <- c(100, 750) # any value possible depending on CNV
source(paste0(path_scripts, "middel_bio_fig2.R"))
outcome <- "vas_s"; outcome.lab <- "Visual analog scale stress (0-100)"; ylim <- c(0, 22)
source(paste0(path_scripts, "middel_bio_fig2.R"))
# sink()
# dev.off()
