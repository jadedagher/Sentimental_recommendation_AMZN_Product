#hello Word 

# Mandatory packages
pkg <- c("jsonlite", "data.table", "dplyr", "tidytext", "tidyr", "stringr", "ggplot2", "gridExtra", "recommenderlab")

# check to see if packages are installed. Install them if they are not, then load them into the R session.
install_all_pkg <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

install_all_pkg(pkg)

# ------------------------------------------------------------------------
# import main data file (reviews_data.json)
# ------------------------------------------------------------------------

reviews_data <- stream_in(file("data/reviews_data.json"))
reviews_data <- flatten(reviews_data) 

# ------------------------------------------------------------------------
# data Enrichment (see pyhton script extract_metadata.py)
# ------------------------------------------------------------------------

# join "reviews_data" table on "product_metadata" table to get:
#  - product title 
#  - product price 
#  - product brand

# To be able to import metadata file into R we must lighten it, so we design 
# a python script to read the big metata file and then create (write) a new CSV 
# file with the data wanted (ASIN, TITlE and PRICE columns)

product_metadata <-  read.csv("data/light_metadata.csv", header=TRUE, sep=",")

# left join 
full_data <- merge(reviews_data, product_metadata, by="asin", all.x = TRUE)
View(head(full_data))

# ------------------------------------------------------------------------
# preprocessing
# ------------------------------------------------------------------------

# purpose: Cleaning full_data dataframe (We want only full data rows, no missing values, no NA)

# converting full_data$product_brand in character to use nchar
# & logical test on full_data$product_brand to see if data exist 
full_data$logicalTestOnStringLength <- sapply(as.character(full_data$product_brand), function(x) nchar(x) > 1)

# counting TRUE and FALSE values
table(full_data$logicalTestOnStringLength)

# filtering only on logicalTestOnStringLength = TRUE (so only where product_brand data exist)
cleaned_data <- subset(full_data, full_data$logicalTestOnStringLength == 'TRUE')

# removing cleaned_data$price with NA to have a clear dataset
cleaned_data <- na.omit(cleaned_data)

# removing logicalTestOnStringLength column from cleaned_data
cleaned_data <- cleaned_data[,1:13]

# converting cleaned_data into data.table 
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

# join each lexicon to the review_words dataframe
reviews_scored <- reviews_words %>%
  left_join(nrc, by = 'word') %>%
  left_join(bing, by = 'word') %>%
  left_join(loughran, by = 'word') %>%
  left_join(afinn, by = 'word')

# get the mean score for each USER
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
# recommendation System based on sentimental analysis score recorded
# ------------------------------------------------------------------------

# test without sentimental score (only overall) > if work > add sentimental score
data_ech_reco <- data.frame(data_ech$reviewerID, data_ech$reviewerName, data_ech$product_title, data_ech$product_price, 
                            data_ech$product_brand, data_ech$overall)
colnames(data_ech_reco) <- c("reviewerID", "reviewerName","product_title", "product_price", "product_brand", "overall")



data_ech_mtx <- as(data_ech_reco, "realRatingMatrix")

data_ech_1000 <- data_ech_mtx[1:1000]

## Split data set into train and test sets (idk what given parameter means....)
e <- evaluationScheme(data_ech_1000, method="split", train=0.8, given=1 ,goodRating=5)


## Recommender
r1 <- Recommender(getData(e, "train"), "UBCF")

## Predictor bur very long to compute
p1 <- predict(r1, getData(e, "known"), type="ratings")
p1

##error mesurement 
error <- rbind(rbind(UBCF = calcPredictionAccuracy(p1, getData(e, "unknown"))))


## https://cran.r-project.org/web/packages/recommenderlab/vignettes/recommenderlab.pdf 
### checker à partir de page 15 jusqu'à  page 26
