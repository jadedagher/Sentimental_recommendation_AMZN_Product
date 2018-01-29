# R Language Project

## 1. Introduction

The goal of this project is to build a little recommender system based on Users similarity. The dataset needs to have reviews and ratings. The dataset is available [here](https://drive.google.com/drive/folders/1pRia7E1BFe0fUKhYsRAEbs9N_tI-yErA?usp=sharing).

## 2. Import and clean the data

### Dataset choice

The choosen dataset deals about Digital Music. Here are the useful parameters : 

reviewerID | asin | product_Title | reviewText | overall|
-----------|------|---------------|------------|--------|
*asin* is the productID and *overall* is a global rating of the product. 

### Python data process

### Data enrichment 

### Problems encoutered

At the beginning of the project, we used the *Clothing, Shoes and Jewelry* dataset from Amazon.
The dataset quality wasn't so good so our algorithm didn't work well. 
By changing the dataset handle us to have better recommendations results.

## 3. Sentimental Analysis

Our dataset contains *text reviews* as a comment of a product. Text isn't so easy to process. With *Sentimental Analysis* method, we can have a numeric rating of a textual review. 

### NRC Scoring

The National Research Council of Canada (NRC) lexicon was developed by crowdsourcing sentiment ratings on Amazon’s Mechanical Turk platform. Words are rated as *positive*, *negative* or one of eight emotions (anger, trust, etc). For this analysis, only *positive* and *negative* ratings are used and _**positive** is converted to **1**_ while _**negative** is converted to **-1**_.

### BING Scoring

The Bing (Hu Liu 2004) lexicon was developed by searching for words adjacent to a predefined list of positive or negative terms. The idea is that if a word consistently shows up next to “happy” that word is probably positive. Again, for this analysis, _**positive** is converted to 1_ while _**negative* is converted to -1_.


### Problems encoutered

We use the overall score as reference. This score is between 0 and 5. So we had to change the output scale of the NRC and BING scoring from {-1, 1} to [0, 5]
because our recommender algorithm is working with 0-5 ratings and not with binary ratings. 



## 4. Recommender system

A recommender system is useful to suggest products a user might be interested.
There are severals methods to recommend products but we will only speak about *User-Based Collaborative Filtering*.

### UBCF Recommendation
-------------------------
*User-Based Collaborative Filtering* method has as goal to find similarity between users. This similarity can be a distance and there are several methods to measure this distance.

##### Cosine as distance function



![Cosinus Similarity](/Users/lux/Documents/esme/r-language/project/screens/cosinus-similarity.png)

##### Pearson correlation as distance function

### Masking technic

## 5. Recommender system evaluation

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

