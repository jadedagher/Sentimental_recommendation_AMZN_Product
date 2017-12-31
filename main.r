#hello Word 

library(jsonlite)
library(data.table)
library(dplyr)
library(tidytext)
library(tidyr)
library(stringr)
library(ggplot2)
library(gridExtra)

# ------------------------------------
# preprocessing
# ------------------------------------

data <- stream_in(file("data.json"))
data <- flatten(data) 

str(data)
head(data)

# convert into data.table 
data <- data.table(data)

# set for sample function, used to retrieve the same results at any time  
set.seed(101)

# N = 10% rows of data 
N <- floor(nrow(data) * (10/100))

# 10% echantillon of data
data_ech <- data[sample(1:nrow(data),N),]

# ------------------------------------
# sentimental reviews analysis
# ------------------------------------

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


# ------------------------------------
# Recommendation System based on sentimental analysis score
# ------------------------------------




# ------------------------------------
# Data Enrichment
# ------------------------------------

# join "reviews_data" table on "product_metadata" table to get:
#  - product title 
#  - product price 
#  - product brand 
#  - product imgUrl 


#product_metadata <-  stream_in(file("metadata.json"))

#left join 
#full_data <- merge(reviews_data, product_metadata, by="asin", all.x = TRUE)







