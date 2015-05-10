# I found the functin substrRight on stack overflow.
# I don't remember the name of the author.

substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

# install.packages("stringr")
library (stringr)
# install.packages("insol")
library(insol)
# install.packages("marelac")
library(marelac)

# install.packages("RODBC")
library(RODBC)
# install.packages("rworldmap")
library(rworldmap)
# install.packages("gdata")
library(gdata)
# install.packages("ggmap")
library(ggmap)


