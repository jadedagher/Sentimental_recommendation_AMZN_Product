#hello Word 

library(jsonlite)
library(data.table)
library(dplyr)
library(tidytext)
library(tidyr)
library(stringr)
library(ggplot2)
library(gridExtra)

# ------------------------------------------------------------------------
# Import main data file (reviews_data.json)
# ------------------------------------------------------------------------

reviews_data <- stream_in(file("data/reviews_data.json"))
reviews_data <- flatten(reviews_data) 

# ------------------------------------------------------------------------
# Data Enrichment (see pyhton script extract_metadata.py)
# ------------------------------------------------------------------------

# join "reviews_data" table on "product_metadata" table to get:
#  - product title 
#  - product price 

# To be able to import metadata file into R we must lighten it, so we design 
# a python script to read the big metata file and then create (write) a new CSV 
# file with the data wanted (ASIN, TITlE and PRICE columns)

product_metadata <-  read.csv("data/light_metadata.csv", header=TRUE, sep=",")

#left join 
full_data <- merge(reviews_data, product_metadata, by="asin", all.x = TRUE)
View(head(full_data))

# ------------------------------------------------------------------------
# preprocessing
# ------------------------------------------------------------------------

# Purpose: Cleaning full_data dataframe (We want only full data rows, no missing values, no NA)

# Converting full_data$product_brand in character to use nchar
full_data$product_brand <- as.character(full_data$product_brand)

# logical test on full_data$product_brand to see if data exist 
full_data$logicalTestOnStringLength <- sapply(full_data$product_brand, function(x) nchar(x) > 1)

# Counting TRUE and FALSE values
table(full_data$logicalTestOnStringLength)

# Filtering only on logicalTestOnStringLength = TRUE (so only where product_brand data exist)
cleaned_data <- subset(full_data, full_data$logicalTestOnStringLength == 'TRUE')

# Removing cleaned_data$price with NA to have a clear dataset
cleaned_data <- na.omit(cleaned_data)

# Removing logicalTestOnStringLength column from cleaned_data
cleaned_data <- cleaned_data[,1:13]

# Converting cleaned_data into data.table 
cleaned_data  <- data.table(cleaned_data)

# set for sample function, used to retrieve the same results at any time  
set.seed(101)

# N = 50% rows of cleaned_data 
N <- floor(nrow(cleaned_data) * (50/100))

# Creating a new dataset with 50% of rows of cleaned_data 
data_ech <- cleaned_data[sample(1:nrow(cleaned_data),N),]

# ------------------------------------------------------------------------
# sentimental reviews analysis (source code: https://goo.gl/iaLjj3)
# ------------------------------------------------------------------------

data_ech_sent <- data.frame(data_ech$reviewerID, data_ech$reviewText, data_ech$overall)
colnames(data_ech_sent) <- c("reviewerID","reviewText", "overall")
data_ech_sent$reviewText <- as.character(data_ech_sent$reviewText)
str(data_ech_sent)

# Create data frame with one line per word
reviews_words <- data_ech_sent %>%
  select(reviewerID, reviewText, overall) %>%
  unnest_tokens(word, reviewText) %>%
  filter(!word %in% stop_words$word, str_detect(word, "^[a-z']+$"))

# sentiment score NRC
nrc <- sentiments %>%
  filter(sentiment %in% c('positive','negative') & lexicon == 'nrc') %>%
  mutate(nrc = ifelse(sentiment == 'positive',1,-1)) %>%
  select(word, nrc)

# sentiment score BING
bing <- sentiments %>%
  filter(lexicon == 'bing') %>%
  mutate(bing = ifelse(sentiment == 'positive',1,-1)) %>%
  select(word, bing)

# sentiment score LOUGHRAN
loughran <- sentiments %>%
  filter(sentiment %in% c('positive','negative') 
         & lexicon == 'loughran') %>%
  mutate(loughran = ifelse(sentiment == 'positive',1,-1)) %>%
  select(word, loughran)

# sentiment score AFINN
afinn <- sentiments %>%
  filter(lexicon == 'AFINN') %>%
  select(word, afinn = score)

# Join each lexicon to the review_words dataframe
reviews_scored <- reviews_words %>%
  left_join(nrc, by = 'word') %>%
  left_join(bing, by = 'word') %>%
  left_join(loughran, by = 'word') %>%
  left_join(afinn, by = 'word')

# Get the mean score for each USER
review_scores_summary <- reviews_scored %>%
  group_by(reviewerID, overall) %>%
  summarise(nrc_score = round(mean(nrc, na.rm = T),3),
            bing_score = round(mean(bing, na.rm = T),3),
            loughran_score = round(mean(loughran, na.rm = T),3),
            afinn_score = round(mean(afinn, na.rm = T),3))

# postprocessing
# ploting results 
afinn.box <- ggplot(review_scores_summary, aes(x = as.character(overall), y = afinn_score))+
  geom_boxplot()+
  labs(x = 'AMZN overall score',
       y = 'AFINN Text Review Score')

nrc.box <- ggplot(review_scores_summary, aes(x = as.character(overall), y = nrc_score))+
  geom_boxplot()+
  labs(x = 'AMZN overall score',
       y = 'NRC Text Review Score')

bing.box <- ggplot(review_scores_summary, aes(x = as.character(overall), y = bing_score))+
  geom_boxplot()+
  labs(x = 'AMZN overall score',
       y = 'Bing Text Review Score')

loughran.box <- ggplot(review_scores_summary, aes(x = as.character(overall), y = loughran_score))+
  geom_boxplot()+
  labs(x = 'AMZN overall score',
       y = 'Loughran Text Review Score')


grid.arrange(afinn.box, nrc.box, bing.box, loughran.box, nrow = 2)


# ------------------------------------------------------------------------
# Recommendation System based on sentimental analysis score recorded 
# ------------------------------------------------------------------------













