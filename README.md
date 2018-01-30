# R Language Project

## 1. Introduction

The goal of this project is to build a little recommender system based on Users similarities by evaluating their product_reviews sentiment. By doing this, we will try to build a score which will be used to evaluate the similarity between the users. To do so, it is mandatory to have at least a dataset that contains a list of reviewerID, product_ID (a.k.a. asin), product_reviews and product_ratings (that we will build afterwards thanks to the sentimental analysis). If you want to try this analysis at home feel free to download the datasets [here](https://drive.google.com/drive/folders/1pRia7E1BFe0fUKhYsRAEbs9N_tI-yErA?usp=sharing).

## 2. Import and Clean data

### Dataset Choice


We chose an Amazon dataset that deals about Digital Music. Here are the useful parameters that will be used along the analysis : 

reviewerID | asin | product_Title | reviewText | overall|
-----------|------|---------------|------------|--------|
A2UI2GW70Q8EXA|B0000002HZ|Too Late to Cry|I think this is by far the best CD I have ever purchased. (...) |5|

*asin* is the product_ID and *overall* is a global rating of the product. 

### Python Data Process

The full dataset is a merge of two files : one with the contains the product reviews by user and the other that contains static products information (title, brand, price). 

As the file containing static products information was too heavy for an upload in R Studio (in memory), we did a simple python script that extract only the usefull columns (*product_title*, *product_price*, *product_brand*) and create a lighter CSV file (*light_metadata.csv*) that can be easily read in memory (The original size was reduce by 3/4).

This step isn't mendatory, but as a end-of-product point of view, suggest products by names gives a better user experience than suggest them by IDs which is too raw.

### Data Merge


Finally, we can import the *light_metadata.csv* into RStudio  

```r
product_metadata <-  read.csv("data/light_metadata.csv", header=TRUE, sep=",")
```

Then, we merge with a *Left Join* both of the files thanks to the *ASIN* parameter. 

```r
full_data <- merge(reviews_data, product_metadata, by="asin", all.x = TRUE)
```

### Dataset Optimization 

Because of this merger, some missing value has been introduced into our main dataset *full_data*

So we did some optimization to have a cleanned and robust dataset without missing or NA values.

By observing the main dataset, the most empty column is "product_brand". That's why we delete every line with an empty value for this parameter. 

### Problems Encoutered

##### Large file importation with R
- Before understanding that the only way to open the large static products information file was to make a script in python, we lost a lot of time trying to open it with R.

##### Dataset Optimization for recommendation system 
- In order to do things well, at the begining, we reduce the main dataset in order to reduce time computing by taking random rows. Unfortunately by doing this the similarity matrix was very little populated and the recommendation system wasn't working well (1 user had his recommendation working on 50). For bearing this problem we order the dataset by product_title and we didn't reduce it to have better performances.

##### Problem with the first Amazon dataset used
- At the beginning of the analysis, we used the *reviews_Clothing_Shoes_and_Jewelry_5.json.gz* dataset from Amazon.
The dataset quality wasn't so good so our algorithm didn't work well (the similarity matrix was almost empty so we didn't have any recommendation). 
By changing the dataset handle us to have better recommendations results.



## 3. Sentimental Analysis

Our dataset contains *text reviews* as a comment of a product. Text isn't so easy to process. With *Sentimental Analysis* method, we can have a numeric rating of a textual review. 

### NRC Scoring

The National Research Council of Canada (NRC) lexicon was developed by crowdsourcing sentiment ratings on Amazon’s Mechanical Turk platform. Words are rated as *positive*, *negative* or one of eight emotions (anger, trust, etc). For this analysis, only *positive* and *negative* ratings are used and _**positive** is converted to **1**_ while _**negative** is converted to **-1**_.

### BING Scoring

The Bing (Hu Liu 2004) lexicon was developed by searching for words adjacent to a predefined list of positive or negative terms. The idea is that if a word consistently shows up next to “happy” that word is probably positive. Again, for this analysis, _**positive** is converted to 1_ while _**negative** is converted to -1_.


### Problems Encoutered

We use the overall score as reference. This score is between 0 and 5. So we had to change the output scale of the NRC and BING scoring from {-1, 1} to [0, 5]
because our recommender algorithm is working with 0-5 ratings and not with binary ratings. 



## 4. Recommender System

A recommender system is useful to suggest products a user might be interested.
There are severals methods to recommend products but we will only speak about *User-Based Collaborative Filtering*.

### UBCF Recommendation
-------------------------
*User-Based Collaborative Filtering* method has as goal to find similarity between users. This similarity can be a distance and there are several methods to measure this distance.

##### Cosine as distance function

This method is based on the scalar product. Each user is a multidimensional vector containing each parameter useful. 
The picture below describes well the understanding of the method. 

![Cosinus Similarity](http://blog.christianperone.com/wp-content/uploads/2013/09/cosinesimilarityfq1.png)

##### Pearson correlation as distance function



### Masking Technic
![Masking Technic](https://jessesw.com/images/Rec_images/MaskTrain.png)

## 5. Recommender System Evaluation

### Methods

### Plots

## 6. Conclusion

## 7. To go further

### Sentimental Analysis
------------------------


##### LOUGHRAN Scoring (option)

The Loughran lexicon is specifically designed for analysis of positivity in shareholder reports. Again, only “positive” and “negative” ratings are used here and they are converted to numeric values.

##### AFINN Scoring (option)

AFINN is a set of words rated on a scale from -5 to 5 with negative numbers indicating negative sentiments and positive numbers indicating positive sentiments. The original scale is retained here.

### IBCF
--------
##### Cosine as distance function

##### Pearson correlation as distance function


## 8. References

1. *Sentimental Analysis :* [https://github.com/joshyazman/tutorials/blob/master/sentiment-analysis/lexicon-comparison/Sentiment%20Analysis%20Comparison.Rmd](https://github.com/joshyazman/tutorials/blob/master/sentiment-analysis/lexicon-comparison/Sentiment%20Analysis%20Comparison.Rmd)
2. *Masking Technic :* [https://jessesw.com/Rec-System/](https://jessesw.com/Rec-System/) § Creating a Training and validation Set

