from bs4 import BeautifulSoup
from bs4 import UnicodeDammit
import requests

indexScorpex = "https://scorpexuke.com/songs/?order=n"


response = requests.get(indexScorpex)

# dammit = UnicodeDammit(response.content)
# print(dammit.unicode_markup)


soup = BeautifulSoup(response.content, 'html.parser')

print(soup.prettify('latin-1'))

