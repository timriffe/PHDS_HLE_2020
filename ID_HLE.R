library(tidyverse)

# some custom functions
source("Functions.R")

# Read in the data (Daniel Schneider gave these to me, haha)
TR <- read_csv("TRv6.csv") 

# take a peek: we have many strata
head(TR)

# define a subset
TRsub <- TR %>% filter(sex == "f",
                       edu == "terciary",
                       time == 1996)
# how many age groups
n  <- nrow(TRsub)
# age interval width..
interval <- 2


# Two containers
Hx <- rep(0, n+1)
Ux <- rep(0, n+1)

# Get transition probabilities
hhx <- TRsub %>% pull(m11)
hux <- TRsub %>% pull(m12)
uux <- TRsub %>% pull(m22)
uhx <- TRsub %>% pull(m21)
hdx <- TRsub %>% pull(m14)
udx <- TRsub %>% pull(m24)

# decide on some starting conditions...
init <- TRsub[1,c("s1_prop","s2_prop")] %>% unlist()
names(init) <- c("H","U")

# Now start the calcs

# we start off with everyone alive:
Hx[1] <- init[1] * interval
Ux[1] <- init[2] * interval

# following ages are all determined
# but they are sequentially dependant
for (i in 1:n){
  Hx[i+1] <- Hx[i] * hhx[i] + Ux[i] * uhx[i]
  Ux[i+1] <- Ux[i] * uux[i] + Hx[i] * hux[i]
}

ages <- seq(48,110,by=2)
HLT <- data.frame(
           age = ages,
           Hx=Hx,
           Ux=Ux,
           hhx=c(hhx, 0),
           hux=c(hux, 0),
           hdx=c(hdx, 0),
           uux=c(uux, 0),
           uhx=c(uhx, 0),
           udx=c(udx, 0))

# Hx and Ux are now like denominators.
# The other columns are directed transition probabilities
# So you can calculate actual transitions as you please

# For example:

HLT %>% 
  mutate(DU = Ux * udx,
         DH = Hx * hdx) %>% 
  select(age, DU, DH) %>% 
  mutate(D = DU + DH) %>% 
  pivot_longer(DU:D, 
               names_to = "Health status",
               values_to = "Deaths") %>% 
  ggplot(aes(x = age, 
             y = Deaths, 
             color = `Health status`, 
             group = `Health status`)) +
  geom_line()
  
# Question: let's say you took those two deaths distributions, 
# can you do distribution statistics on them? Does it change the
# interpretation of anything, knowing that these are mixing popultions?
# Tricky tricky! 

# If you want to make an overall statement on health
# inequality, best take into account the mixing somehow. See suggestions
# in the simulation script. See also the Caswell & Zarulli paper for a 
# matrix solution (or stay tuned for his workshop), which by the way 
# would totally be doable using  increment decrement lifetables like 
# this, but I haven't seen it expressed as such. 


IDLT <- function(dat, init, interval = 2){
  n  <- nrow(dat)
  Hx <- rep(0, n+1)
  Ux <- rep(0, n+1)
  
  hhx <- dat %>% pull(m11)
  hux <- dat %>% pull(m12)
  uux <- dat %>% pull(m22)
  uhx <- dat %>% pull(m21)
  
  hdx <- dat %>% pull(m14)
  udx <- dat %>% pull(m24)
  # if not given then assume constant.
  if (missing(init)){
    u1   <- matrix(c(hhx[1],hux[1],uhx[1],uux[1]),2)
    v1   <- eigen(u1)$vectors[,1]
    init <- v1 / sum(v1)
  }
  #cat(init)
  Hx[1] <- init[1] * interval
  Ux[1] <- init[2] * interval
  
  for (i in 1:n){
    Hx[i+1] <- Hx[i] * hhx[i] + Ux[i] * uhx[i]
    Ux[i+1] <- Ux[i] * uux[i] + Hx[i] * hux[i]
  }
  ages <- c(min(dat$age)-interval,dat$age)
  data.frame(age = ages,
             Hx=Hx,
             Ux=Ux,
             hhx=c(hhx, 0),
             hux=c(hux, 0),
             hdx=c(hdx, 0),
             uux=c(uux, 0),
             uhx=c(uhx, 0),
             udx=c(udx, 0))
}














