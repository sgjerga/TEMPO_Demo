###### make plot for one selected outcome across all time points and groups
plot(c(-.5,5.5), ylim, pch="", axes=F, ylab=outcome.lab, xlab="")
xadj.times <- c(-.15,0,.6,1.05)
xticks <- rep(c(0,2,4), each=4) + xadj.times
n.groups <- 3
axis(1, at=xticks, labels = rep(xadj.times*100, 3), las=2)
axis(2)
for(i in c(0,2,4)) {
  polygon(x=c(0,.45,.45,0) + i, y=c(0,0,rep(max(ylim)*.9,2)), 
          col="grey", border=NA, density=25)
}
text(c(0,2,4)+.2, max(ylim)*.88, "Intervention", adj=c(1,1), srt=90)
text(c(0,2,4)+.2, max(ylim)*.95, paste("Month", c(1,3,6)), adj=c(0,0))


for (i in 1:3) { # 3 months
  for (j in 1:n.groups) { # 3 groups
    group.j <- rasing[, groups]==levels(rasing[, groups])[j]
    data.ij <- subset(rasing, month==c(1,3,6)[i] & group.j)
    outcome.ij <- subset(data.ij, select=outcome)
    xpos <- c(0,2,4)[i] + xadj.times[c(1,3,4)] + xadj.groups * (j-1)
    log.outcome.ij <- subset(data.ij, select = paste0("log.", outcome))
    to.plot <- matrix(nrow=3, ncol=4, dimnames=list(letters[1:3], c("n", "M", "SD", "SE")))
    cat("\n========================================\n\n", 
        outcome, " Month ", i, " ", levels(rasing[, groups])[j], ":\n\n", sep="")
    for (k in 1:3) { # 3 time points a-c
      outcome.ijk <- outcome.ij[data.ij$time==letters[k], ]
      to.plot[k, ] <- unlist(describe(outcome.ijk)[c(2:4, 13)])
      # add p-values, change within group:
      if(k>1) { # not time a
        log.outcome.now <- log.outcome.ij[data.ij$time==letters[k], ]
        log.outcome.before <- log.outcome.ij[data.ij$time==letters[k-1], ]
        within <- t.test(log.outcome.now, log.outcome.before, paired=T)
        cat("Within-group change from", letters[k-1], "to", letters[k], ":\n")
        print(within)
        within.sig <- ifelse(within$p.value < .001, "***",
                             ifelse(within$p.value < .01, "**",
                                    ifelse(within$p.value < .05, "*", "")))
        text(xpos[k], to.plot[k, 2], within.sig, adj=c(1,0), col=rasing.col[j], ) # left upper side
        # add p-values, difference against CONTROL, adjusted for previous time:
        if(j<3) {# not CONTROL
          data.i.control <- subset(rasing, month==c(1,3,6)[i] & group4f=="CONTROL")
          log.outcome.i.control <- subset(data.i.control, select = paste0("log.", outcome))
          log.outcome.now.control <- log.outcome.i.control[data.i.control$time==letters[k], ]
          log.outcome.before.control <- log.outcome.i.control[data.i.control$time==letters[k-1], ]
          log.outcome.now.combined <- c(log.outcome.now, log.outcome.now.control)
          log.outcome.before.combined <- c(log.outcome.before, log.outcome.before.control)
          group <- c(rep("intervention", length(log.outcome.now)),
                     rep("CONTROL", length(log.outcome.now.control)))
          between <- lm(log.outcome.now.combined ~ group + log.outcome.before.combined)
          cat("\n\nBetween-group difference against CONTROL at", letters[k], "adjusted for", letters[k-1], ":\n")
          print(summary(between))
          cat("\n\n")
          between.p.value <- summary(between)$coef[2,4]
          between.sig <- ifelse(between.p.value < .001, "***",
                               ifelse(between.p.value < .01, "**",
                                      ifelse(between.p.value < .05, "*", "")))
          text(xpos[k], to.plot[k, 2], between.sig, adj=c(0,1), col=rasing.col[j], ) # right lower side
          
        }
               }
    }
    print(round(to.plot, 2))
    lines(xpos, to.plot[, "M"], col=rasing.col[j], type="b", pch=j)
    segments(xpos, to.plot[, "M"] - to.plot[, "SE"],
             xpos, to.plot[, "M"] + to.plot[, "SE"],
             col=rasing.col[j])
}}

# legend("topright", fill=rasing.col[1:n.groups], legend=levels(rasing[, groups])[1:3], bty="n")
