# Path to folder where script is running from
$gScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Do date checks. If true, script will check the date on every song PDF to see if it has been updated
$doDateChecks = $false

# Path to base site
$baseUrl = "http://www.scorpexuke.com/"

# Path to page that lists every song (the 'order=n' parameter ensures newer songs are listed first)
$songPageUrl = $baseUrl + "ukulele-songs.html?order=n"

# RegEx to match song page link, song title and artist on the main song list page
# $regEx_Songs = "<a.*?href='(.*?)'.*?>(.+)<\/a>[^-]+-\s+(.*?)\s*<\/td>"  # this version did not have properly escaped meta-chars: '<' & '>'
$regEx_Songs = "\<a.*?href='(.*?)'.*?\>(.+)\<\/a\>[^-]+-\s+(.*?)\s*\<\/td\>"

# Property list to map song page link, Song Title and Artits to named properties 
$props1 = @(
		@{ n="SongPage"; e={$_.Groups[1].Value} }, 
		@{ n="Title"; e={[System.Web.HttpUtility]::HtmlDecode( $_.Groups[2].Value.Trim() ) } }, 
		@{ n="Artist"; e={[System.Web.HttpUtility]::HtmlDecode( $_.Groups[3].Value.Trim() ) } }
	)
	
# RegEx to match the document (normally PDF) download link on the song page
$regEx_DownloadLink = "href='(pdffiles\/.+?)\s?'"

# RegExt to filter list of songs by Artist and/or Song Title
$regEx_ArtistFilter  = ".*"		# Use ".*" to match EVERY possible Artist, including blanks
$regEx_TitleFilter = "."

# Path to root for saving downloaded files
$DownloadRoot = $gScriptRoot

# Path to log file
$gLogFilePath = join-path $DownloadRoot "Downloader.Log"

# Random delays between blocks of downloads
$delayParams = @{
	"MinSongsPerBlock" = 50;
	"MaxSongsPerBlock" = 75;
	"InterBlockDelaySeconds" = 60;
	"BlockCounter" = 50;
	"InterSongDelayMilliseconds" = 3000
	}
	


function Write-Log($Message){

	Write-Host $message
	
	Write-Output ("{0:dd/MM/yy HH:mm:ss} {1}" -f (get-date), $Message) | Out-File -Append -Encoding ascii -FilePath $gLogFilePath

}

function fix-foldername($original){

	# patch specific characters
	$original = $original -Replace "’", "'"
	$original = $original -Replace '"', "'"
	$original = $original -replace "\\", "-"
	$original = $original -replace "\/", "-"
	$original = $original -replace "\.", ""
	
	# remove any other non-ascii characters
	$original -Replace "[^\x00-\x7F]", ""

}

function Download-File($uri, $filePath, $dateCheck){

	$fileExists = Test-Path -Path $filePath
	$fileOutOfDate = $false

	if ( $fileExists -and $dateCheck) {
	
		$localFileDate = (Get-Item -Path $filePath).LastWriteTime
		
		try {
			
			write-log -Message ( "- checking for updates" )
			$webFileInfo = Invoke-WebRequest -Uri $uri -Method Head
			$webFileDate = get-date $result.webFileInfo.Headers['Last-Modified']
			$fileOutOfDate = ( $webFileDate -gt $localFileDate )
			
		} catch {

			throw ( "Failed to get date of '{0}'" -f $uri )			
		
		}
		
	}
	
	if ( ! $fileExists -or $fileOutOfDate ) {
	
		try {
			
			Write-Log -Message ( " - downloading" )
			$webclient = New-Object system.net.WebClient
			$webclient.DownloadFile($uri, $filePath)
			
		} catch {
		
			throw ( "Failed to download '{0}'" -f $uri )

		}
		
	}
	
}

Write-Log -Message "Downloader Started"

# Create WebClient and download the main page
$wc = New-Object system.net.WebClient

$proxy = New-Object System.Net.WebProxy -ArgumentList "http://proxy.nec.com.au:9090/"
$proxy.UseDefaultCredentials
$wc.Proxy = $proxy

# Download HTML of the song list page
$songListPageHTML = $wc.DownloadString($songPageUrl)

Write-Log -Message ( "Downloaded page '{0}' - {1} bytes" -f $songPageUrl, $songListPageHTML.length )

# Parse song list page HTML to find links to individual songs
$songPageLinks = $songListPageHTML | Select-String $regEx_Songs -AllMatches

Write-Log -Message ( "- Found {0} song page links" -f $songPageLinks.Matches.count )

$songCounter = 0

$filteredSongList = @($songPageLinks.Matches |
						Select-Object $props1 |
						Where-Object { $_.Artist -match $regEx_ArtistFilter -and $_.Title -match $regEx_TitleFilter }
					)
						
if ( $filteredSongList.Count -lt $songPageLinks.Matches.Count ) {

	Write-Log -Message ( "- Filtered download list contains {0} items" -f $filteredSongList.Count )

} else {

	# full list - export to CSV
	$filteredSongList | Export-Csv -Delimiter "," -Encoding Ascii -NoTypeInformation -Path ( Join-Path $DownloadRoot "SongList.csv" )
	
}

$filteredSongList |
	%  {
		$songCounter +=1
		Write-Log -Message ( "Processing: {0} of {1} - {2}" -f $songCounter, ($filteredSongList.Count), $_.SongPage )
		
		try {
			$songPageHtml = $wc.DownloadString($baseUrl + $_.SongPage)
		
			$pdfLink = $baseUrl + ( $songPageHtml | Select-String $regEx_DownloadLink ).Matches.Groups[1].Value
		
			# Reset folderPath to prevent previous value being carried forward and used in the event of an error
			$folderPath = ""
			
			# Some songs don't have 'artist' info, so we can't store the file under an 'artist' folder
			if ( $_.Artist ) {
				$folderPath = Join-Path $DownloadRoot ( fix-foldername -original $_.Artist )
				if ( ! ( Test-Path -LiteralPath $folderPath ) ) {
					$newFolder = New-Item -Path $folderPath -ItemType Directory
				}
				if ( ! ( Test-Path -LiteralPath $folderPath ) ) {
					$folderPath = $DownloadRoot
				}
			} else { 
				$folderPath = join-path $DownloadRoot "\[unknown]" 
				$newFolder = New-Item -Path $folderPath -ItemType Directory -ErrorAction SilentlyContinue
			}
			
			$filePath = Join-Path $folderPath ($pdfLink -split "/")[-1]

			Write-Log -Message ( "- '{0}', '{1}', '{2}', '{3}'" -f $_.Artist, $_.Title, $pdfLink, $filePath )
				
			Download-File -uri $pdflink -filePath $filePath -dateCheck $doDateChecks

		} catch {
		
			Write-Log -Message ( "ERROR: {0}" -f $Error[0].ToString() )
		
		}
		
		# wait for a moment
		Start-Sleep -Milliseconds $delayParams.InterSongDelayMilliseconds
		
		# Decrement block counter. If block complete, pause then reset the block counter
		$delayParams.BlockCounter -= 1
		if ( $delayParams.BlockCounter -lt 1 ) {
			Start-Sleep -Seconds $delayParams.InterBlockDelaySeconds
			$delayParams.BlockCounter = Get-Random -Minimum $delayParams.MinSongsPerBlock -Maximum $delayParams.MaxSongsPerBlock
		}
		
	
	}

Write-Log -Message "Downloader Finished"