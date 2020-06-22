from bs4 import BeautifulSoup
import requests

indexScorpex = "https://scorpexuke.com/songs/?order=n"

proxies = {
  "http": "http://andrew.britton%40nec.com.au:ClaraPandy7@proxy.nec.com.au:9090",
  "https": "http://andrew.britton%40nec.com.au:ClaraPandy7@proxy.nec.com.au:9090"
}

response = requests.get(indexScorpex, proxies)

# dammit = UnicodeDammit(response.content)
# print(dammit.unicode_markup)



soup = BeautifulSoup(response.content, 'html.parser')

print(soup.prettify('latin-1'))

