import requests

proxies = {
  'http': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090'
}

indexURL = "http://scorpexuke.com/songs/?order=n"

r = requests.get(indexURL, proxies=proxies)

print(r.text)
