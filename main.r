#hello Word 

# Mandatory packages
pkg <- c("jsonlite", "data.table", "dplyr", "tidytext", "tidyr", "stringr", "ggplot2", "gridExtra", "recommenderlab", "reshape2")

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

#setorder(data_ech, product_title)

#data_ech <- cleaned_data[1:20000,]

# Creating a new dataset with 50% of rows of cleaned_data 
data_ech <- cleaned_data[sample(1:nrow(cleaned_data),N),]

# ------------------------------------------------------------------------
# sentimental reviews analysis (source code: https://goo.gl/iaLjj3)
# ------------------------------------------------------------------------

data_ech_sent <- data.frame(data_ech$reviewerID, data_ech$asin, data_ech$product_title, data_ech$reviewText, data_ech$overall)
colnames(data_ech_sent) <- c("reviewerID", "asin","product_title", "reviewText", "overall")
data_ech_sent$reviewText <- as.character(data_ech_sent$reviewText)
str(data_ech_sent)

# Create data frame with one line per word
reviews_words <- data_ech_sent %>%
  select(reviewerID, asin, product_title, reviewText, overall) %>%
  unnest_tokens(word, reviewText) %>%
  filter(!word %in% stop_words$word, str_detect(word, "^[a-z']+$"))

# sentiment score NRC
nrc <- sentiments %>%
  filter(sentiment %in% c('positive','negative') & lexicon == 'nrc') %>%
  mutate(nrc = ifelse(sentiment == 'positive',5,0)) %>%
  select(word, nrc)

# sentiment score BING
bing <- sentiments %>%
  filter(lexicon == 'bing') %>%
  mutate(bing = ifelse(sentiment == 'positive',5,0)) %>%
  select(word, bing)

# sentiment score LOUGHRAN
loughran <- sentiments %>%
  filter(sentiment %in% c('positive','negative') 
         & lexicon == 'loughran') %>%
  mutate(loughran = ifelse(sentiment == 'positive',5,0)) %>%
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
  group_by(reviewerID, asin, product_title, overall) %>%
  summarise(nrc_score = round(mean(nrc, na.rm = TRUE),0),
            bing_score = round(mean(bing, na.rm = TRUE),0),
            loughran_score = round(mean(loughran, na.rm = TRUE),0),
            afinn_score = round(mean(afinn, na.rm = TRUE),0))

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


grid.arrange(nrc.box, bing.box, loughran.box, afinn.box, nrow = 2)

# ------------------------------------------------------------------------
# recommendation System based on sentimental analysis score recorded
# ------------------------------------------------------------------------

# test without sentimental score (only overall) > if work > add sentimental score

reco <- function(score_column, ratioTest, ratioTrain){
  
  set.seed(70)

  review_scores_summary_reco <- as.data.frame(review_scores_summary)
  review_scores_summary_reco <- na.omit(review_scores_summary_reco)
  
  data_ech_reco <- data.frame(review_scores_summary_reco$reviewerID, review_scores_summary_reco$product_title, review_scores_summary_reco[,score_column])
  colnames(data_ech_reco) <- c("reviewerID","product_title", "score")
  
  data_ech_reco$reviewerID <- as.numeric(data_ech_reco$reviewerID)
  
  setorder(data_ech_reco, product_title)
  
  # converted data_ech_reco into a recommenderlab format called realRatingMatrix
  g <- acast(data_ech_reco, reviewerID~ product_title)
  R <- as.matrix(g)
  r <- as(R, "realRatingMatrix")
  
  ratings <- r[rowCounts(r) >= 4, colCounts(r) >= 6]
  ratings1 <- ratings[rowCounts(ratings) > 2,]
  
  # This function shows what the sparse matrix looks like.
  # getRatingMatrix(ratings[c(1:5),c(1:4)])
  
  # Histogram of getRatings using Normalized Scores
  # hist(getRatings(normalize(ratings)), breaks=100, xlim = c(-2,2), main = "Normalized-Scores Histogram")
  # hist(getRatings(normalize(ratings, method="Z-score")), breaks = 100, xlim = c(-2,2), main = "Z-score Histogram")
  
  # We randomly define the which_train vector that is True for users in the training set and FALSE for the others.
  # Will set the probability in the training set as 80%
  which_train <- sample(x = c(TRUE, FALSE), size = nrow(ratings1), replace = TRUE, prob = c(ratioTest, ratioTrain))
  data_ech_reco_train <- ratings1[which_train, ]
  data_ech_reco_test <- ratings1[!which_train, ]
  
  # -----UBCF
  # The method computes the similarity between users with cosine
  UBCF_model <- Recommender(data = data_ech_reco_train, method = "UBCF")
  UBCF_predicted <- predict(object = UBCF_model, newdata = data_ech_reco_test, n = 3)
  
  # list with the recommendations to the test set users.
  reco_matrix <- sapply(UBCF_predicted@items, function(x) { colnames(ratings)[x] })
  
  # recommendation only for user with numericalID = 13 
  reco_matrix$`13`
}

# recomendation with overall score
reco(score_column = "overall", ratioTest = 1, ratioTrain = 0.4)
# recomendation with sentimental score
reco(score_column = "nrc_score", ratioTest = 1, ratioTrain = 0.4)
reco(score_column = "bing_score", ratioTest = 1, ratioTrain = 0.4)
reco(score_column = "loughran_score", ratioTest = 1, ratioTrain = 0.4)
reco(score_column = "afinn_score", ratioTest = 1, ratioTrain = 0.4)


# ------------------------------------------------------------------------
# Evaluating the Recommender Systems
# ------------------------------------------------------------------------

eval <- function(score_column){
  
  set.seed(70)
  
  review_scores_summary_reco <- as.data.frame(review_scores_summary)
  review_scores_summary_reco <- na.omit(review_scores_summary_reco)
  
  data_ech_reco <- data.frame(review_scores_summary_reco$reviewerID, review_scores_summary_reco$product_title, review_scores_summary_reco[,score_column])
  colnames(data_ech_reco) <- c("reviewerID","product_title", "score")
    
  data_ech_reco$reviewerID <- as.numeric(data_ech_reco$reviewerID)
  
  setorder(data_ech_reco, product_title)
  
  # converted data_ech_reco into a recommenderlab format called realRatingMatrix
  g <- acast(data_ech_reco, reviewerID~ product_title)
  R <- as.matrix(g)
  r <- as(R, "realRatingMatrix")
  
  ratings <- r[rowCounts(r) >= 4, colCounts(r) >= 6]
  ratings1 <- ratings[rowCounts(ratings) > 2,]
  
  eval_sets <- evaluationScheme(data = ratings1, method = "cross-validation", k = 4, given = 2, goodRating = 3)
  size_sets <-sapply(eval_sets@runsTrain, length)
  
  models_evaluated <- list(UBCF_cos = list(name = "UBCF", param = list(method = "cosine")))
  
  # In order to evaluate the models, we need to test them, varying the number of items.
  n_recommendations <- c(1, 10, 50, 100, 200, 500, 1000)
  
  # evaluate the models
  list_results <- evaluate(x = eval_sets, method = models_evaluated, n = n_recommendations)
  
  # extract the related average confusion matrices
  avg_matrices <- lapply(list_results, avg)
  
  # explore the performance evaluation
  head(avg_matrices$UBCF_cos[, 5:8])
  
  # plot
  # plot(list_results, annotate = 1)
  # plot(list_results, "prec/rec", annotate = 1, legend = "bottomright", ylim = c(0,0.4))
}

# recomendation with overall score
eval("overall")
# recomendation with sentimental score
eval("nrc_score")
eval("bing_score")
eval("loughran_score")
eval("afinn_score")
