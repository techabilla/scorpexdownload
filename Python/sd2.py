import os
import sys
import requests
from bs4 import BeautifulSoup
import re
import configparser

proxies = {
  'http': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090',
  'https': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090'
}

# *nix
localDir = "/home/pi/ScorpexDownloader/PDF"
dirSep = "/"

# Win
localDir = "C:\Repos\ScorpexDownload\Python\PDF"
dirSep = "\\"

indexScorpex = "https://scorpexuke.com/songs/?order=n"
urlMatch = "scorpexuke\\.com/[^/]+$"

def GetPage(url, proxies, maxAttempts, timeout):

    attemptCounter = 0
    successFlag = 0
    while attemptCounter < maxAttempts and successFlag == 0:
        try:
            if proxies is None:
                response = requests.get(url)
            else:
                response = requests.get(url, proxies=proxies)
            successFlag = 1
        except:
            attemptCounter +=1

    if successFlag == 1:
        return response
    else:
        return None

def GetSongDetails(divSongLink):
    divText = divSongLink.text
    artist = divText.rpartition(chr(8211))[-1].strip()
    title = divText.partition("  ")[0].strip()
    keyandchords = divText.partition("  ")[2].partition(chr(8211))[0].strip()
    key = keyandchords.partition("/")[0]
    pageURL = divSongLink.a.get("href")

    return { "title": title, "artist": artist, "key": key,
            "chordCount": keyandchords.rpartition("/")[0],
            "filenameGuess": pageURL.rpartition("/")[-1] + ".pdf",
            "filenameBugFormat": "{} - {} - Scorpex ({}).pdf".format(artist, title, key),
            "pageURL": pageURL,"downloadURL": ""
            }

try:

    # indexPage_Response = requests.get(indexScorpex, proxies=proxies)
    indexPage_Response = GetPage(indexScorpex, proxies, 5, 30)
    indexPage = BeautifulSoup(indexPage_Response.content, "html.parser")
    divEntryContent = indexPage.find("div", class_="entry-content")
    linkList = divEntryContent.find_all("a", href=re.compile(urlMatch))

    songList = []
    for link in linkList:
        songDetails = GetSongDetails(link.parent)
        songList.append(songDetails)
        if os.path.isfile(localDir + dirSep + songDetails['filenameGuess']):
            nothing = 0
        else:
            print("MISSING: {} - {} : {}".format(songDetails["artist"], songDetails["title"], songDetails["pageURL"]))

    print("Found %i songs" % len(songList))

    print(songList[0])

except:
    errType, errValue, errTraceback = sys.exc_info()
    print(errType)
    print(errValue)
    print(errTraceback)

print("finished")

