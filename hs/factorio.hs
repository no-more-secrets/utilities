#!/usr/bin/env stack
-- stack --resolver lts-9.21 --install-ghc runghc

import Text.Printf (printf)

-- Global Constants -----------------------------------------------------

yellowRate = 13.333
redRate    = yellowRate*2.0
blueRate   = yellowRate*3.0

-- Per Query ------------------------------------------------------------

desiredItemsPerSecond :: Float
desiredItemsPerSecond = 0.7 -- how many per second do we need

itemName       = "Blue Circuit" -- what is being produced
timePerCycle   = 10.0     -- seconds
itemMultiplier = 1.0      -- how many you get in itemTime

ingredients :: [(String, Float)]
ingredients = [
  ("Red Circuit",   2.0),
  ("Green Circuit", 20.0),
  ("Sulfuric Acid", 5.0)
  ]

cyclesPerSecond = 1.0/timePerCycle

-- Per Factory ----------------------------------------------------------

itemsPerFactoryPerCycle  = itemMultiplier
itemsPerFactoryPerSecond = itemsPerFactoryPerCycle*cyclesPerSecond

depPerFactoryPerCycle :: Float -> Float
depPerFactoryPerCycle inputQuantityPerFactoryPerCycle = inputQuantityPerFactoryPerCycle

depPerFactoryPerSecond :: Float -> Float
depPerFactoryPerSecond inputQuantityPerFactoryPerCycle = depPerFactoryPerCycle inputQuantityPerFactoryPerCycle * cyclesPerSecond

-- Total ----------------------------------------------------------------

numFactories  = desiredItemsPerSecond/itemsPerFactoryPerSecond

depPerSecond inputQuantityPerFactoryPerCycle = depPerFactoryPerSecond inputQuantityPerFactoryPerCycle * numFactories

beltsStr :: Float -> String
beltsStr x = printf "[%2.3fy, %2.3fr, %2.3fb]" (x/yellowRate) (x/redRate) (x/blueRate) 

depStr :: (String, Float) -> String
depStr (name, inputQuantityPerFactoryPerCycle) = r
  where
    f = printf "%-30s" (printf "Total Input of %ss:" name :: String) :: String
    r = printf "%s %7s/s  %s" f rateStr (beltsStr rate) :: String
    rate = depPerSecond inputQuantityPerFactoryPerCycle
    rateStr = printf "%2.3f" rate :: String

main :: IO ()
main = do
    printf "To produce %f %ss per second:\n" desiredItemsPerSecond itemName
    printf "\n"
    printf "  - Number of Factories: %f\n" numFactories
    printf "\n"
    putStr $ unlines $ map (printf "  - %s") $ map depStr $ ingredients
    printf "\n"
