# Data Enrichment

# trying to join "reviews_data" table on "product_metadata" table to get:
#  - product title 
#  - product price 
#  - product brand

# source code from: http://jmcauley.ucsd.edu/data/amazon/links.html (Reading the data - Pandas data frame)

import pandas as pd
import gzip

def parse(path):
  g = gzip.open(path, 'rb')
  for l in g:
    yield eval(l)

def getDF(path):
  i = 0
  df = {}
  for d in parse(path):
    df[i] = d
    i += 1
  return pd.DataFrame.from_dict(df, orient='index')

df = getDF('data/meta_Digital_Music.json.gz')

light_df = df.loc[:,['asin', 'title', 'price', 'brand']]

light_df = light_df.rename(index=str, columns={"title": "product_title", "price": "product_price", "brand": "product_brand"})

light_df.to_csv('data/light_metadata.csv', sep=',')