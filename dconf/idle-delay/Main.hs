module Main where

import Control.Concurrent (threadDelay)
import Control.Monad (when)
import Data.List (find, isPrefixOf)
import Data.Maybe (isJust)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Data.Time.LocalTime (getZonedTime)
import qualified System.IO.Strict as S
import Text.Printf (printf)

screensaverFile :: FilePath
screensaverFile = "/etc/dconf/db/site.d/screensaver"
--screensaverFile = "/home/dsicilia/screensaver"

isIdleDelayLine :: String -> Bool
isIdleDelayLine line = words line == ["idle-delay=uint32", "300"]

readScreensaverFile :: IO [String]
readScreensaverFile = do
  lines `fmap` S.readFile screensaverFile

doesScreensaverFileNeedUpdate :: IO Bool
doesScreensaverFileNeedUpdate = do
  lines' <- readScreensaverFile
  return $ isJust $ find isIdleDelayLine $ lines'

fixIdleDelayLine :: String -> String
fixIdleDelayLine = unwords . (++["3600"]) . take 1 . words
  
updateIfIdleDelayLine :: String -> String
updateIfIdleDelayLine line
  | isIdleDelayLine line = fixIdleDelayLine line
  | otherwise = line

updateScreensaverFile :: IO ()
updateScreensaverFile = do
  lines' <- readScreensaverFile
  let edited = map updateIfIdleDelayLine lines'
  writeFile screensaverFile (unlines edited)
  
loop :: IO ()
loop = do
  timeStr <- formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S" <$> getZonedTime
  needsUpdate <- doesScreensaverFileNeedUpdate
  when needsUpdate $ do
    printf "%s | needs update.\n" timeStr
    updateScreensaverFile
  --printf "%s | sleeping.\n" timeStr
  threadDelay 1000000 -- microseconds
  loop

main :: IO ()
main = do
  printf "Running.\n"
  loop
