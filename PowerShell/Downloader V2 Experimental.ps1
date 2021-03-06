# Path to folder where script is running from
$gScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$scorpexConfig = @{
	SongsPageURL = "http://www.scorpexuke.com/ukulele-songs.html?order=n";
	RegEx_Songs = "\<a.*?href='.*?\=(.*?)&.*?\>(.+)\<\/a\>[^-]+-\s+(.*?)\s*\<\/td\>";
	PropertySelectors = @(
			@{ n="FileName"; e={$_.Groups[1].Value} }, 
			@{ n="Title"; e={[System.Web.HttpUtility]::HtmlDecode( $_.Groups[2].Value.Trim() ) } }, 
			@{ n="Artist"; e={[System.Web.HttpUtility]::HtmlDecode( $_.Groups[3].Value.Trim() ) } },
			@{ n="FileURL"; e={"{0}/{1}" -f "http://www.scorpexuke.com/pdffiles", $_.Groups[1].Value}}
		);
	}

function fix-foldername($original){

	if ( $original -eq "" ) { $original = "[unknown]" }

	# patch specific characters
	$original = $original -Replace "’", "'"
	$original = $original -Replace '"', "'"
	$original = $original -replace "\\", "-"
	$original = $original -replace "\/", "-"
	$original = $original -replace "\.", ""
	
	# remove any other non-ascii characters
	$original -Replace "[^\x00-\x7F]", ""

}

function get-scorpexSongList($scorpexConfig){

	try {

		$webClient = New-Object system.net.WebClient
		
		$rawHTML = $webClient.DownloadString($scorpexConfig.SongsPageURL)
		
		$filteredHTML = $rawHTML | Select-String $scorpexConfig.RegEx_Songs -AllMatches
		
		$filteredHTML.Matches | Select-Object $scorpexConfig.PropertySelectors
		
	} catch {
	
		throw ( "ERROR in get-scorpexSongList: {0}" -f $Error[0].ToString() )
	
	}

}

$DownloadRoot = $gScriptRoot

$webClient = New-Object system.net.WebClient

$SongList = get-scorpexSongList -scorpexConfig $scorpexConfig

$DateCheckFlag = $True

if ( $SongList ) {

	Write-Host ( "Song list conatains {0} items" -f $SongList.Count )
	
	$SongList | 
		% {
			
			$filePath = Join-Path ( Join-Path $DownloadRoot ( fix-foldername $_.Artist ) ) $_.FileName
			
			$downloadFlag = $False
		
			if ( Test-Path -LiteralPath  $filePath ) {
			
				if ( $DateCheckFlag ) {
				
					Write-Host ( "- checking for newer version of {0}" -f $filePath )
				
					$WebFileDate = Get-Date  (Invoke-WebRequest -Uri $_.FileURL -Method Head).Headers['Last-Modified']
					
					if ( $WebFileDate -gt (Get-Item -Path $filePath).LastWriteTime ) {
					
						Write-Host ( "FILE OUT OF DATE: {0}" -f $filePath )
						$downloadFlag = $True
						
					} else {
					
						# As soon as we find a file that is up to date, there's no point in checking any more file dates,
						# because the list of songs is in 'newest' order.
						
						$DateCheckFlag = $False
						
						Write-Host ( "- no further date checks" )
					
					}
				
				}
			
			} else {
			
				Write-Host ( "FILE MISSING: {0}" -f $filePath )
				$downloadFlag = $true
				
			}
			
			if ( $DownloadRequiredFlag ) {
				Write-Host ( "- downloading: {0} " -f $_.FileURL )
				$webClient.DownloadFile($_.FileURL, $filePath)
			}
			
		}
		
} else {

	# Song List Empty
	
}

