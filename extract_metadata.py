# Data Enrichment

# trying to join "reviews_data" table on "product_metadata" table to get:
#  - product title 
#  - product price 
#  - product brand 

from pprint import pprint

input_file=open('metadata.json', 'r')
output_file=open('light_metadata.json', 'w')

json_decode=json.load(input_file)

result = []

for item in json_decode:
	my_dict = {}
	my_dict['asin'] = item.get('asin')
	my_dict['title'] = item.get('title')
	my_dict['price'] = item.get('price')
	my_dict['brand'] = item.get('brand')
	print (my_dict)
	result.append(my_dict)

back_json = json.dumps(result, output_file)

output_file.write(back_json)
output_file.close() 


