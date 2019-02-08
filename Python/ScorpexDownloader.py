import os
import sys
import requests
from bs4 import BeautifulSoup
import re
import configparser

#proxies = {
#  'http': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090',
#  'https': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090'
#}

proxies = None 
# *nix
localDir = "/home/pi/ScorpexDownloader/PDF"
dirSep = "/"

# Win
#localDir = "C:\Repos\ScorpexDownload\Python\PDF"
#dirSep = "\\"

indexScorpex = "https://scorpexuke.com/songs/?order=n"
urlMatch = re.compile("scorpexuke\\.com/[^/]+$")
pdfUrlTemplate = "https://scorpexuke.com/pdffiles/{}.pdf"
pdfHrefMatch = re.compile("/pdffiles/.+?\.pdf")

def GetWebResource(url, proxies, maxAttempts, timeout):

    attemptCounter = 0
    successFlag = 0
    while attemptCounter < maxAttempts and successFlag == 0:
        try:
            if proxies is None:
                response = requests.get(url)
            else:
                response = requests.get(url, proxies=proxies)
            
            response.raise_for_status()

            successFlag = 1
        except:
            attemptCounter +=1

    if successFlag == 1:
        return response
    else:
        return None

def DownloadFile(localFilename, url, proxies, maxAttempts, timeout):
    print("- downloading {} to {}".format(url, localFilename))
    resource = GetWebResource(url, proxies, 1, 10)
    if ( resource is not None and len(resource.content) > 0):
        localFile = open(localFilename, "wb")
        localFile.write(resource.content)
        localFile.close()
        return True
    else:
        return False

def GetSongDetails(divSongLink):
    divText = divSongLink.text
    artist = divText.rpartition(chr(8211))[-1].strip().replace("\\","-").replace("/","-")
    if (len(artist) == 0):
        artist = "(unknown)"
    title = divText.partition("  ")[0].strip().replace("\\","-").replace("/","-")
    keyandchords = divText.partition("  ")[2].partition(chr(8211))[0].strip()
    key = keyandchords.partition("/")[0]
    pageURL = divSongLink.a.get("href")

    return { "title": title, "artist": artist, "key": key,
            "chordCount": keyandchords.rpartition("/")[0],
            "filenameGuess": pageURL.rpartition("/")[-1] + ".pdf",
            "urlGuess": pdfUrlTemplate.format(pageURL.rpartition("/")[-1]),
            "filenameBugFormat": "{} - {} - Scorpex ({}).pdf".format(artist, title, key),
            "pageURL": pageURL
            }

#def DownloadSong():

try:

    indexPage_Response = GetWebResource(indexScorpex, proxies, 5, 30)
    indexPage = BeautifulSoup(indexPage_Response.content, "html.parser")
    divEntryContent = indexPage.find("div", class_="entry-content")
    linkList = divEntryContent.find_all("a", href=urlMatch)

    logFile = open("ScorpexDownloader.log", "w")
    logFileTemplate = "{}\r\n - '{}'\r\n - '{}'\r\n"

    songDictionary = {}
    for link in linkList:

        songDetails = GetSongDetails(link.parent)

        if os.path.isfile(localDir + dirSep + songDetails["filenameBugFormat"]):
            songDetails["status"] = "Present"
        elif os.path.isfile(localDir + dirSep + songDetails["filenameGuess"]):
            songDetails["status"] = "Present"
            os.rename(localDir + dirSep + songDetails["filenameGuess"], localDir + dirSep + songDetails["filenameBugFormat"])
        else:
            if DownloadFile(localDir + dirSep + songDetails["filenameBugFormat"], songDetails["urlGuess"], proxies, 1, 10):
                songDetails["status"] = "Present"
            else:
                songPage_Response = GetWebResource(songDetails["pageURL"], proxies, 5, 30)
                songPage = BeautifulSoup(songPage_Response.content, "html.parser")
                pdfURLtag = songPage.find("a", href=pdfHrefMatch)
                pdfURL = pdfURLtag.get("href")
                if DownloadFile(localDir + dirSep + songDetails["filenameBugFormat"], pdfURL.strip(), proxies, 1, 10):
                    songDetails["status"] = "Present"
                else:
                    songDetails["status"] = "Missing"

        logFile.write(logFileTemplate.format(songDetails["pageURL"], songDetails["filenameGuess"], songDetails["filenameBugFormat"]))

        if songDetails["status"] != "Present": 
            print("{}: {} - {} : {}".format(songDetails["status"], songDetails["artist"], songDetails["title"], songDetails["pageURL"]))

        dictKey = songDetails["pageURL"]
        songDictionary[dictKey] = songDetails
        
    logFile.close()
    # print("Found %i songs" % len(songDictionary))

except:
    errType, errValue, errTraceback = sys.exc_info()
    print(errType)
    print(errValue)
    print(errTraceback)

print("finished")

