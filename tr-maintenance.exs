defmodule TR do

  # [ { path            e.g.: "t:/Pubs/P2"
  #   , recsByGroup     List of lists, each sublist is a newspaper/magazine      
  #   , nonTRMs         Files where the base conforms to \d{4} but the
  #   }                 extension is not TRM or trm. All other files are ignored.
  # , {...}
  # , {...}
  # ]
  # 
  # [ {"t:/Pubs/P2"
  #   , [ ["8898", "8897", (...)]
  #     , ["8799", "8798", (...)]
  #     , [...]
  #     ]
  #   , ["4877.ex"]
  #   }
  # , {"t:/Pubs/P3"
  #   , [ ["8898", (...)]
  #     , ["8799", (...)]
  #     , [...]
  #     ]
  #   , []
  #   }
  # , {...}      
  # ]
                 #["P1", "P2", "P3"]  
  def list_groups(trmFolders) do
    runlog("...TR MAINTENANCE...")
    
    trmFolders
    |> Enum.map( fn(e) ->
          Path.join(~w(t: Pubs #{e}))
       end)
    |> Enum.map(
         fn(path) -> 
           {:ok, files} = File.ls(path)
           
           {recs, nonTRMs} =
             files
             |> Enum.reverse
             |> filter3DigitSysPrompts
             |> Enum.partition(
                  &Regex.match?(~r/(trm|TRM)$/, &1)
                )
           
           recsByGroup =
             recs
             |> baseFileName
             |> groupByMagazine

           {path, recsByGroup, nonTRMs}  # === recTpl
         end)
  end
  
  def iterate_groups(recTpl) do
    recTpl
    |> Enum.each(
         fn({fromPath, recsByGroup, _nonTRMs}) ->
           recsByGroup
           |> Enum.each(
                fn(lst) ->
                  lst
                  |> move_files_if_more_than_70_articles(fromPath, "n:/backed-up-recordings/archived")
                  |> rename_files_in_group(fromPath)
                end)
         end)
    runlog("....................")
  end
  
  def show_groups_above_70(recTpl) do
    recTpl
    |> Enum.map(
         fn({p,l, _n}) ->                                                             
           longs =
             l
             |> Enum.map(
                  fn(lst) -> {hd(lst), length(lst)} 
                end)
             |> Enum.filter(
                  fn({_,e}) -> e > 70 
                end)
             |> Enum.map(
                  fn({i,e}) -> {i, to_string(e)}
                end)
                
             {p, longs}                                                                          
         end)
  end

  # HELPERS
 
  defp rename_files_in_group(lst, path) do
    articleNumber = Regex.run(~r/\d{2}/, hd(lst)) |> hd
    
    from =
      Enum.join([articleNumber, "98"])
      |> String.to_integer
    
    lst
    |> Enum.zip(from..50)
    |> Enum.reverse()
    |> Enum.map(
         fn({from, to}) ->
           fromFile = Enum.join([from, ".TRM"])
           toFile   = Enum.join([to, ".TRM"])
           
           fromFullPath = Path.join([path, fromFile])
           toFullPath   = Path.join([path, toFile])

           case String.to_integer(from) == to do
             false ->
               runlog("#{path} RENAMED   #{from}   TO   #{to}")
               File.rename(fromFullPath, toFullPath)
             true  ->
               :ok
           end
         end)
  end
  
  defp move_files_if_more_than_70_articles(lst, fromPath, toPath) do
    case length(lst) > 70 do
      true  ->
        {toMove, newLst} = 
          lst
          |> Enum.split(30)

        toMove
        |> Enum.map(
             fn(e) ->
               recFileName = Enum.join([e, ".TRM"])
               toFileName  = renameMovedFiles(e, fromPath)
        
               fromFullPath = Path.join([fromPath, recFileName])
               toFullPath   = Path.join([  toPath,  toFileName])
               
               runlog("MOVING #{fromFullPath}")
               File.rename(fromFullPath, toFullPath)
             end)
        newLst
        
      false ->
        lst
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
  
  defp renameMovedFiles(fileBaseName, pathToExtractPubNameFrom) do
    pubFolder = Regex.run(~r/\S{2}$/, pathToExtractPubNameFrom) |> hd

    time = Enum.join(timestamp, "-")
    
    Enum.join(
      [ time, "_", pubFolder,
        "_",
        fileBaseName,
        ".TRM"])
  end
  
  defp filter3DigitSysPrompts(enum) do
    enum
    |> Enum.filter(
         fn(e) ->
           Regex.match?(~r/\d{4}\./, e)
         end)
  end
  
  defp baseFileName(enum) do
    enum
    |> Enum.map(
         fn(e) ->
           String.split(e, ".")
           |> hd
         end)
  end
  
  defp groupByMagazine(enum) do
    enum
    |> Enum.chunk_by(
         fn(e) ->
           Regex.run(~r/^(\d{2})\d{2}$/,e)
           |> tl
         end)
  end
end



TR.list_groups(~w(P2 P3 P4)) |> TR.iterate_groups