import linecache
import os
import sys
import requests
from bs4 import BeautifulSoup
from bs4 import UnicodeDammit
import re
import configparser

#proxies = {
#  'http': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090',
#  'https': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090'
#}

proxies = None 
# *nix
localDir = "/home/pi/Ukulele/Scorpex"
# localDir = "/home/pi/Scripts/ScorpexDownloader/test"
dirSep = "/"

# Win
#localDir = "C:\Repos\ScorpexDownload\Python\PDF"
#dirSep = "\\"

indexScorpex = "https://scorpexuke.com/songs/?order=n"
urlMatch = re.compile("scorpexuke\\.com/[^/]+$")
pdfUrlTemplate = "https://scorpexuke.com/pdffiles/{}.pdf"
pdfHrefMatch = re.compile("/pdffiles/.+?\.pdf")

def PrintException():
    exc_type, exc_obj, tb = sys.exc_info()
    f = tb.tb_frame
    lineno = tb.tb_lineno
    filename = f.f_code.co_filename
    linecache.checkcache(filename)
    line = linecache.getline(filename, lineno, f.f_globals)
    print('EXCEPTION IN ({}, LINE {} "{}"): {}'.format(filename, lineno, line.strip(), exc_obj))


def GetWebResource(url, proxies, maxAttempts, timeout):

    attemptCounter = 0
    successFlag = 0
    while attemptCounter < maxAttempts and successFlag == 0:
        try:
            if proxies is None:
                response = requests.get(url, timeout=timeout)
            else:
                response = requests.get(url, proxies=proxies, timeout=timeout)
            
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
    resource = GetWebResource(url, proxies, maxAttempts, timeout)
    if ( resource is not None and len(resource.content) > 0):
        localFile = open(localFilename, "wb")
        localFile.write(resource.content)
        localFile.close()
        return True
    else:
        return False
    
def StringFixup(stringToFix):
    uSpecial1 = u"\u2013" # EN DASH 8211 dec
    
    return stringToFix.replace("\\","-").replace("/","-").replace(uSpecial1,"-")

def GetSongDetails(divSongLink):
    uSpecial1 = u"\u2013" # EN DASH 8211 dec
    divText = divSongLink.text.replace(u"\u2018","'").replace(u"\u2019","'").replace(u"\u201c","'").replace(u"\u201d","'").replace(u"\u2026","-")
    
    # artist = divText.rpartition(chr(8211))[-1].strip().replace("\\","-").replace("/","-").replace(uSpecial1,"-")
    artist = StringFixup(divText.rpartition("-")[-1].strip())
    if (len(artist) == 0):
        artist = "(unknown)"
    
    # title = divText.partition("!  ")[0].strip().replace("\\","-").replace("/","-").replace(uSpecial1,"-")
    title = StringFixup(divSongLink.a.string)
    
    keyandchords = divText.partition("  ")[2].partition(chr(8211))[0].strip()
    
    key = keyandchords.partition("/")[0]

    pageURL = divSongLink.a.get("href")

    return { "title": title, "artist": artist, "key": key,
            "chordCount": keyandchords.rpartition("/")[0],
            "filenameGuess": pageURL.rpartition("/")[-1] + ".pdf",
            "urlGuess": pdfUrlTemplate.format(pageURL.rpartition("/")[-1]),
            "filenameBugFormat": "{} - {} - Scorpex ({}).pdf".format(title, artist, key),
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
            print("- present {}".format(songDetails["filenameBugFormat"]))
        elif os.path.isfile(localDir + dirSep + songDetails["filenameGuess"]):
            songDetails["status"] = "Present"
            print("- present {}".format(songDetails["filenameGuess"]))
            os.rename(localDir + dirSep + songDetails["filenameGuess"], localDir + dirSep + songDetails["filenameBugFormat"])
            print("- renamed to {}".format(songDetails["filenameBugFormat"]))
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
    PrintException()
    # errType, errValue, errTraceback = sys.exc_info()
    # print(errType)
    # print(errValue)
    # print(errTraceback)

print("finished")
