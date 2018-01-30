# Sentimental analysis and recommendation system on AMAZON products dataset 

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

The goal of sentimental analysis is to : 

1. Split a product_review sentence into words. 
2. Give a sentiment of each word with a score
3. Count number of -1 and 1 to determine the sentence sentiment 


![Explain Sentimental Analysis](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/sentimental_explain.png?raw=true)

### NRC Scoring

The National Research Council of Canada (NRC) lexicon was developed by crowdsourcing sentiment ratings on Amazon’s Mechanical Turk platform. Words are rated as *positive*, *negative* or one of eight emotions (anger, trust, etc). For this analysis, only *positive* and *negative* ratings are used and _**positive** is converted to **1**_ while _**negative** is converted to **-1**_.

### BING Scoring

The Bing (Hu Liu 2004) lexicon was developed by searching for words adjacent to a predefined list of positive or negative terms. The idea is that if a word consistently shows up next to “happy” that word is probably positive. Again, for this analysis, _**positive** is converted to 1_ while _**negative** is converted to -1_.

### Statistical analysis


![sentimental vs overall](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/sentimental_vs_overall.png?raw=true)


This box-plots compare how a rating value change between the overall score and a sentimental analysis method score.

For example, in the box plot below, for the NRC method, a 5-rating as overall equals a 4-rating as NRC **in average**.


### Problems Encoutered

- We use the overall score as reference. This score is between 0 and 5. So we had to change the output scale of the NRC and BING scoring from {-1, 1} to [0, 5]. 
We did so because we have to plot the result of the algorithm and by doing this, the comparaison is easier. 



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

### Masking Technic

With collaborative filtering, classic technic (split the full data into two datasets : one for train and the other for test) is not going to work because you need all of the user/item interactions to find the proper matrix factorization. A better method is to hide a certain percentage of the user/item interactions from the model during the training phase chosen at random. Then, check during the test phase how many of the items that were recommended the user actually ended up purchasing in the end. 

Our test set is an exact copy of our original data. The training set, however, will mask a random percentage of user/item interactions and act as if the user never rated the item (making it a sparse entry with a zero). We then check in the test set which items were recommended to the user that they ended up actually purchasing. If the users frequently ended up purchasing the items most recommended to them by the system, we can conclude the system seems to be working.

![Masking Technic](https://jessesw.com/images/Rec_images/MaskTrain.png)



### Results

Here are the songs recommended by the recommender system for the user 79 using the BING and NRC sentimental analysis.

The masking ratio is set at 0.4.


**Overall** *(without sentimental analysis)*

![Overall Recommendation](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/reco_overall.png?raw=true)


**NRC**

![NRC Recommendation](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/reco_nrc.png?raw=true)


**BING**

![BING Recommendation](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/reco_bing.png?raw=true)




#### Interpretation

Obviously, the recommended songs are not the same for each method. 

The reason is that each song's review has a different score because of the sentimental analysis. When the recommender works, it recommends on differents data for each method.



## 5. Recommender System Evaluation

### Method 

#### The `evaluateScheme` function has as parameters :

- input cleaned data : *ratings1*,
- a method of validation : *cross-validation*, 
- the number of time the evaluation is done (10 by default for cross-validation), 
- the number of single item given for the evaluation : *2*,
- the minimal rating to consider as *positive* and useful for the evaluation : *3*. 

```r
eval_sets <- evaluationScheme(data = ratings1, method = "cross-validation", given = 2, goodRating = 3)
```

###### Cross-validation method consists on creating differents train/test dataset and run each of them to reduce overfitting. 

###### We set the minimal rating at 3 because we consider a song can be considered as good with this minimal rating. Moreover, it allows us to recommend with more data and to improve the accuracy.


#### The model method is set to *UBCF cosine* (or *UBCF Pearson*)

```r
models_evaluated <- list(UBCF_cos = list(name = "UBCF", param = list(method = "cosine")))
```

#### The number of recommendations is a vector of several wanted values

```r
n_recommendations <- c(1, 10, 50, 100, 200, 500, 1000)
```

We recommend up to 1000 songs for the user. 


### The `evaluate` function needs a scheme, a method and a number of recommendations define upper. 
```r
evaluate(x = eval_sets, method = models_evaluated, n = n_recommendations)
```


### Results

All of the results are multiplied by 100 to be read as percentage directly. 

![](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/eval_all.png?raw=true)


### Interpretation

For all the results, the precision decreases with the increase of the number of recommendations. 

![](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/pr_all.png?raw=true)

*This graphs shows the precision/recall ration depending on the number of recommendations.*

The overall method has a better precision but it's probably due to the change of scale applies to the *NRC* and *BING* methods. 

For our dataset, the *NRC* technic is more precise than the *BING* technic. 



## 6. Conclusion

Let's resume the steps we went through : 

- Clean the data
- Get a sentiment rating for each method
- Test the recommendation for user 79
- Evaluate the recommender system 


For the digital music dataset, the recommendation isn't very accurate: the precision is below 10%.

In the recommendation world, explicit recommendation (like the one we did) are not well popular. Few people rates their film or songs. Because of it's lack of data, our recommender can't learn well and have a pertinent suggestion.


Our biggest issue was to work with the prebuild function of *recommenderlab* package because we didn't understand well how works each function. 
For example, implemant the masking technic in R was not so easy. We can mask a ration of data but it's hard to compare the predicted value and the 


## 7. To go further

### Sentimental Analysis
------------------------


##### LOUGHRAN Scoring (option)

The Loughran lexicon is specifically designed for analysis of positivity in shareholder reports. Again, only “positive” and “negative” ratings are used here and they are converted to numeric values.

Here are the results of the recommendation, in the same conditions described in the *Sentimental Analysis* section : 
![Overall Recommendation](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/reco_laughran.png?raw=true)

One result here is in common with the Overall recommendation. It is due to the inside numeric value conversion which is more precise than only change the scale. 

##### AFINN Scoring (option)

AFINN is a set of words rated on a scale from -5 to 5 with negative numbers indicating negative sentiments and positive numbers indicating positive sentiments. The original scale is retained here.

Here are the results of the recommendation, in the same conditions described in the *Sentimental Analysis* section : 
![Overall Recommendation](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/reco_afinn.png?raw=true)

### IBCF
--------
We test the same dataset with the IBCF method (Item-Based Collaborative Filtering). 
Here is a results-curve to compare with UBCF and random methods. 
![all_curves](https://github.com/jadedagher/sentimental_recommendation_AMZN_Product/blob/master/img/all_curves.png?raw=true)

For this dataset, UBCF method performances is better than the IBCF one until 100 recommendations. After 100 recommendations, the precision/recall are the same for the UBCF, IBCF and random method. 


## 8. References

1. *Sentimental Analysis :* [https://github.com/joshyazman/tutorials/blob/master/sentiment-analysis/lexicon-comparison/Sentiment%20Analysis%20Comparison.Rmd](https://github.com/joshyazman/tutorials/blob/master/sentiment-analysis/lexicon-comparison/Sentiment%20Analysis%20Comparison.Rmd)
2. *Masking Technic :* [https://jessesw.com/Rec-System/](https://jessesw.com/Rec-System/) § Creating a Training and validation Set

