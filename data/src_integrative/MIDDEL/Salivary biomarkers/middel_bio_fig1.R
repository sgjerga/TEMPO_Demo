###### make plot for one selected outcome across all time points (groups below each other?)
ylim <- range(rasing[, outcome], na.rm=T)
plot(c(0,7), ylim*3, pch="", axes=F, ylab=outcome, xlab="")
xticks <- rep(c(1,3,6), each=3) + xadj.times * (0:2)
axis(1, at=xticks, labels = rep("", length(xticks)))
axis(2, at=ylim[2]/2 + ylim[2] * 2:0, labels = c("GMT", "RCS", "Control"))

for (i in c(1,3,6)) { # month
  for (j in 1:3) { # group 1:3
    for (k in 1:3) {
      #k<-1;i<-1; j<-1
      i;j;k
      data.ijk <- subset(rasing, month==i & group==j & time==letters[k])
      outcome.ijk <- subset(data.ijk, select=outcome)
      xpos <- i + xadj.times * (k-2)
      yadj <- ylim[2] * (3-j)
      side <- "both" # ifelse(k==1, "left", "right")
      vioplot(outcome.ijk + yadj, col=k+1, at=xpos, side=side, add=T)
      if(dots) points(jitter(rep(xpos, nrow(data.ijk))), unlist(outcome.ijk) + yadj, pch=".", col="grey")
  }}}
