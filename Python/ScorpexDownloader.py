import os
# import urllib.request
# import urllib.parse
# from urllib.error import HTTPError, URLError
import socket
import re
import requests
from bs4 import BeautifulSoup

print("Started")

proxies = {
  'http': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090',
  'https': 'http://andrew.britton:ClaraPandy4@proxy.nec.com.au:9090'
}

scorpexurl = "https://scorpexuke.com/songs/?order=n"

print("Opening: " + scorpexurl)

page = requests.get(scorpexurl, proxies=proxies)

print("- loaded " + str(len(page.content)) + " bytes")

saveFile = open('indexpage.html','wb')
saveFile.write(page.content)
saveFile.close()
print("- written page content to file")

linkFile = open("links.txt","w")
soup = BeautifulSoup(page.content, "html.parser")
entryContent = soup.find("div", class_="entry-content")
print("- found entry-content div")

urlMatch = "scorpexuke\\.com/[^/]+$"

linkList = entryContent.find_all("a", href=re.compile(urlMatch))
print("- found " + str(len(linkList)) + " links")

# *nix
localDir = "/home/pi/ScorpexDownloader/PDF"
dirSep = "/"

# Win
localDir = "C:\Repos\ScorpexDownload\Python\PDF"
dirSep = "\\"

pdfMatch = re.compile("pdffiles")

for link in linkList:
    songPageURL = str(link.get("href"))

    # Extract Song Title and Artist
    divText = link.parent.text
    songTitle = divText.partition("  ")[0].strip()
    songArtist = divText.rpartition(chr(8211))[-1].strip()
    songKey = divText.partition("  ")[2].partition(chr(8211))[0].strip()

    print(songTitle + " - " + songArtist + " - (" + songKey + ")")
    alternateLocalFileName = localDir + dirSep + songTitle + " - " + songArtist + " - (" + songKey + ")" + ".pdf"

    # Before we open the song page, guess the filename and test. If it exists, skip loading the song page

    fileNameGuess = localDir + dirSep + songPageURL.rpartition("/")[-1] + ".pdf"

    if (not(os.path.isfile(fileNameGuess) and os.path.getsize(fileNameGuess) > 0)):
        print("Opening: " + songPageURL)
        try:
            tries=5
            songPage = None
            while songPage is None and tries>0:
                try:
                    songPage = requests.get(songPageURL, proxies=proxies)
                except:
                    songPage = None
                    tries = tries - 1
            
            songPageBytes = songPage.content
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
                            localFilename = localDir + dirSep + filename
                            if os.path.isfile(localFilename) and os.path.getsize(localFilename) > 0:
                                print("- file already exists")
                            else:
                                print("- downloading to " + localFilename)
                                tries=5
                                songPDF = None
                                while songPDF is None and tries>0:
                                    try:
                                        songPDF = requests.get(pdfURL, proxies=proxies)
                                    except:
                                        songPDF = None
                                        tries = tries - 1
                                songPDFBytes = songPDF.content

                                pdfFile = open(localFilename, "wb")
                                pdfFile.write(songPDFBytes)
                                pdfFile.close()
                            
        except:
            print("ERROR - failed to load page")
        
        
linkFile.close()

print("Finished")
