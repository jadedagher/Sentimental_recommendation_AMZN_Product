#hello Word 

install.packages("jsonlite")
install.packages("tidytext")

library(jsonlite)
library(data.table)
library(dplyr)
library(tidytext)
library(tidyr)

# ------------------------------------
# preprocessing

data <- stream_in(file("data.json"))
data <- flatten(data) 

str(data)
View(data[1:1000,])

# convert into data.table 
data <- data.table(data)

# set for sample function, used to retrieve the same results at any time  
set.seed(101)

# N = 10% des lignes pour avoir exactement 1e+05 obs
N <- floor(nrow(data) * (10/100))

# 10% echantillon of data
data_ech <- data[sample(1:nrow(data),N),]

# ------------------------------------
# sentimental reviews analysis
data_ech_sent <- data.frame(data_ech$reviewerID, data_ech$reviewText)
colnames(data_ech_sent) <- c("reviewerID","reviewText")

# create data frame with one line per word
reviews_words <- data_ech_sent %>%
  select(data_ech_sent$reviewText) %>%
  unnest_tokens(word, text) %>%
  filter(!word %in% stop_words$word, str_detect(word, "^[a-z']+$"))


