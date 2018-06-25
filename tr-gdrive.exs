# c ["C:/azkizartdologmertnemtudom/gd/Access News/gd-to-an-autocopier.exs"]

defmodule TR.Gdrive do
  def mv_and_convert(fromPath, baseTo, readerList) do
    runlog("...GDRIVE MAINTENANCE...")
    readerList
    |> Enum.map(
         fn({folder, pub, articleNum}) ->
           runlog("#{folder}")
           fullFromPath = Path.join(fromPath, folder)
           fullToPath   = Path.join(baseTo, pub)

           fullFromPath
           |> list_and_filter
              # because I dare not touch the the working
              # setup on the RSR side...
           |> convert_if_not_wav_or_mp3(fullFromPath)
           |> rename_articles([], articleNum, fullFromPath, fullToPath)
           |> move_to_TR
         end)
    runlog("........................")
  end

  defp move_to_TR(files) do
    files
    |> Enum.map(
         fn({from, to}) ->
           runlog("GDRIVE MOVE FILES\n      #{from}\n   -> #{to}")
           File.rename(from, to)
         end)
  end
  
  defp rename_articles([f|rest], acc, num, from, to) do
    newF = to_string(num) <> getExt(f)
    fromFile = Path.join(from, f)
      toFile = Path.join(to,   newF)
      
    newAcc = [ {fromFile, toFile} | acc]
    rename_articles(rest, newAcc, num+1, from, to)    
  end
  defp rename_articles([], acc, _, _, _) do
    acc
  end

  # TODO: sometimes hangs on ffmpeg (CULPRIT: same filename with different extension)
  #       limit time? because it usually ok on the next run
  defp convert_if_not_wav_or_mp3(list, fullFromPath) do
    list
    |> Enum.map(
         fn(file) ->
           case Regex.match?(~r/\.(mp3|wav)/, getExt(file)) do
             true  ->
               file
             false ->
               ffmpegPath = "C:/azkizartdologmertnemtudom/TR-maintenance-script/ffmpeg.exe"

               newFile =
                 file
                 |> Path.extname
                 |> (&Path.basename(file, &1)).()
                 |> (&<>/2).(".wav")
                
                newFilePath = Path.join(fullFromPath, newFile)
                filePath    = Path.join(fullFromPath, file)                
 
                runlog("GDRIVE CONVERT\n      #{filePath}\n   -> #{newFilePath}")
 
                System.cmd(ffmpegPath, ["-i", filePath, newFilePath])
                File.rm(filePath)
                
                newFile
           end
         end)
  end 

  defp list_and_filter(path) do
    filteredExts = ~r/\.(msi|ini|exe|dll|bat|exs|none)/
    
    path
    |> File.ls!
    |> filter_nonaudio_files(filteredExts)
  end
  
  # filters directories as well
  defp filter_nonaudio_files(files, filteredExts) do
    files
    |> Enum.filter(
         fn(file) ->
           !Regex.match?(filteredExts, getExt(file))
         end)
  end
  
  defp getExt(fileName) do
    ext = fileName
          |> Path.extname
          |> String.downcase
    
    case ext do
      "" -> ".none"
      _  -> ext
    end
  end

  defp runlog(msg) do
    logfile = "n:/backed-up-recordings/log"
    {:ok, dev} = File.open(logfile, [:append])
    
    [date, time] = timestamp
    dateString = date |> Enum.join("/")
    timeString = time |> Enum.join(":")
    IO.puts(dev, "#{dateString} #{timeString} - #{msg}")
    File.close(dev)
  end

  defp timestamp do
    {{year, month, day}, {hour, min, sec}} = :calendar.local_time
    [year, month, day, hour, min, sec]
       |> Enum.map(
            fn(e) -> 
              e
              |> to_string
              |> String.pad_leading(2, "0")
            end)
       |> Enum.chunk(3)
  end
end

TR.Gdrive.mv_and_convert(
  "C:/azkizartdologmertnemtudom/gd/Access News",
  "t:/Pubs",
  [{"sacramento-bee",                          "P2", 7500},
   {"auburn-journal",                          "P3", 8400},
   {"east-bay-times",                          "P3", 7600},
   {"roseville-press-tribune",                 "P2", 6500},
   {"sf-weekly",                               "P3", 7700},
   {"Annette Fucles",                          "P4", 7400}, 
   {"Julie Parker/Carmichael Times",           "P2", 6700}, 
   {"Julie Parker/Fort Bragg Advocate-News",   "P3", 9000},
   {"Julie Parker/The Mendocino Beacon",       "P3", 9100},
   {"Julie Parker/Mental Floss",               "P4", 5700},
   {"Julie Parker/Atlas Obscura",              "P4", 5700},
   {"Santa Rosa Press Democrat",               "P3", 8900},
   {"Bay Area Bites",                          "P3", 7800},
   {"comstocks",                               "P2", 5400},
   {"Npr",                                     "P4", 9000},
   {"senior news",                             "P3", 6400},
   {"Eureka Times Standard",                   "P3", 6700},
   {"stockton-record",                         "P3", 8700},
   {"Ferndale Enterprise",                     "P3", 6800},
   {"Mad River Union",                         "P3", 6600},
   {"Modesto Bee",                             "P3", 8600},
   {"SF Gate",                                 "P3", 7400},
   {"sacramento_press",                        "P2", 8500},
   {"P1/lucky",                                "P1", 9200}, 
   {"P1/safeway-walt",                         "P1", 8500},
   {"P1/bel-air-walt",                         "P1", 8700},
   {"P1/la_superior",                          "P1", 9300},
   {"P1/walmart",                              "P1", 6500},
   {"P1/bel-air",                              "P1", 8600},
   {"P1/sprouts",                              "P1", 9100},
   {"P1/savemart",                             "P1", 8800},
   {"P1/safeway",                              "P1", 8400},
   {"P1/foods-co",                             "P1", 8900},
   {"Davis Enterprise",                        "P2", 6400},
   {"North Coast Journal",                     "P3", 6500},
   {"Mountain Democrat",                       "P3", 8800},
   {"Sports Illustrated",                      "P4", 6600},
   {"Sunset",                                  "P4", 7700},
   {"money",                                   "P4", 8900},
   {"entertainment-weekly",                    "P4", 6500},
   {"people",                                  "P4", 6400},
   {"union",                                   "P3", 8500},
   {"cooking-light",                           "P4", 7600},
   {"sacramento-news-and-review",              "P2", 8400},
   {"sactown",                                 "P2", 5500}])