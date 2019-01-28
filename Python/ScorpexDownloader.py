import os
import urllib.request
import urllib.parse
from urllib.error import HTTPError, URLError
import socket
import re
from bs4 import BeautifulSoup

print("Started")
scorpexurl = "https://scorpexuke.com/songs/?order=n"

print("Opening: " + scorpexurl)
page = urllib.request.urlopen(scorpexurl)
pagebytes = page.read()
print("- loaded " + str(len(pagebytes)) + " bytes")

saveFile = open('noheaders.txt','wb')
saveFile.write(pagebytes)
saveFile.close()
print("- written page content to file")

linkFile = open("links.txt","w")
soup = BeautifulSoup(pagebytes, "html.parser")
entryContent = soup.find_all("div", class_="entry-content")
print("- found entry-content div")

# urlMatch = "scorpexuke\\.com/[a-zA-Z0-9_]*?$"
urlMatch = "scorpexuke\\.com/[^/]+$"

linkList = entryContent[0].find_all("a", href=re.compile(urlMatch))
print("- found " + str(len(linkList)) + " links")

localDir = "/home/pi/ScorpexDownloader/PDF"
pdfMatch = re.compile("pdffiles")

for link in linkList:
    songPageURL = str(link.get("href"))
    
    print("Opening: " + songPageURL)
    try:
        
        tries=5
        songPage = None
        while songPage is None and tries>0:
            try:
                songPage = urllib.request.urlopen(songPageURL, timeout=10)
            except:
                songPage = None
                tries = tries - 1
        
        songPageBytes = songPage.read()
        print("- loaded " + str(len(songPageBytes)) + " bytes")
        
        print("- parsing")
        songSoup = BeautifulSoup(songPageBytes, "html.parser")
        if songSoup is None:
            print("ERROR - failed to parse")
        else:
            songEntryHeader = songSoup.find("header", class_="entry-header")
            if songEntryHeader is None:
                print("ERROR - could not find entry-header")
            else:
                songEntryHeaderText = songEntryHeader.string
                print("- header text: " + str(songEntryHeaderText))
            
                songEntryContent = songSoup.find("div", class_="entry-content")
                if songEntryContent is None:
                    print("ERROR - could not find entry-content div")
                else:
                    pdfLink = songSoup.find("a", href=pdfMatch)
                    if pdfLink is None:
                        print("ERROR - could not find PDF link")
                    else:
                        pdfURL = str(pdfLink.get("href"))
                        print("- PDF URL: " + pdfURL)
                        filename = pdfURL.rpartition("/")[-1]
                        localFilename = localDir + "/" + filename
                        if os.path.isfile(localFilename):
                            print("- file already exists")
                        else:
                            print("- downloading to " + localFilename)
                            tries=5
                            songPDF = None
                            while songPDF is None and tries>0:
                                try:
                                    songPDF = urllib.request.urlopen(pdfURL, timeout=10)
                                except:
                                    songPDF = None
                                    tries = tries - 1
                            songPDFBytes = songPDF.read()
                            pdfFile = open(localFilename, "wb")
                            pdfFile.write(songPDFBytes)
                            pdfFile.close()
                        
    except URLError:
        print("ERROR - failed to load page")
        
        
linkFile.close()

print("Finished")
