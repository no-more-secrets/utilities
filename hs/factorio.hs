#!/usr/bin/stack
-- stack --resolver lts-9.21 runghc

import Text.Printf (printf)

-- Global Constants -----------------------------------------------------

yellowRate = 13.333
redRate    = yellowRate*2.0
blueRate   = yellowRate*3.0

-- Per Query ------------------------------------------------------------

desiredItemsPerSecond :: Float
desiredItemsPerSecond = 25.0 -- how many per second do we need

itemName       = "Blue Circuit" -- what is being produced
timePerCycle   = 10.0           -- seconds
itemMultiplier =  1.0           -- how many you get in itemTime

ingredients :: [(String, Float)]
ingredients = [
  ("red circuits",   2.0),
  ("green circuits", 20.0)--,
  --("sulfuric acids", 5.0)
  ]

-- Per Factory ----------------------------------------------------------

cyclesPerSecond = 1.0/timePerCycle

itemsPerFactoryPerCycle  = itemMultiplier
itemsPerFactoryPerSecond = itemsPerFactoryPerCycle*cyclesPerSecond

depPerFactoryPerCycle :: Float -> Float
depPerFactoryPerCycle inputQuantityPerFactoryPerCycle =
    inputQuantityPerFactoryPerCycle

depPerFactoryPerSecond :: Float -> Float
depPerFactoryPerSecond inputQuantityPerFactoryPerCycle =
    depPerFactoryPerCycle inputQuantityPerFactoryPerCycle * cyclesPerSecond

-- Total ----------------------------------------------------------------

numFactories  = desiredItemsPerSecond/itemsPerFactoryPerSecond

depPerSecond :: Float -> Float
depPerSecond inputQuantityPerFactoryPerCycle =
    depPerFactoryPerSecond inputQuantityPerFactoryPerCycle * numFactories

roundUpToHalf :: Float -> Float
roundUpToHalf x = case closeEnough of
                   True  -> x
                   False -> fromIntegral (ceiling (2.0*x)) / 2.0
 where
   nearestTwiceInteger = fromIntegral $ round (2.0*x)
   distanceFromNearestInteger = abs (nearestTwiceInteger-2.0*x)
   closeEnough = distanceFromNearestInteger < 0.01

toBelts :: Float -> (Float, Float, Float)
toBelts rate = (roundUpToHalf $ rate/yellowRate
               ,roundUpToHalf $ rate/redRate
               ,roundUpToHalf $ rate/blueRate
               ) 

uncurry3 f (x, y, z) = f x y z

depStr :: (String, Float, (Float, Float, Float)) -> String
depStr (name, rate, (by, br, bb)) = r
  where
    f = printf "%-30s" (printf "%s" name :: String)
    r = printf "%s %9s %s" (f :: String) rateStr beltsStr
    rateStr  = if rate < 0 then "" else printf "%2.1f/s" rate
    yellowBeltStr = printf "%2.1f" by :: String
    redBeltStr    = printf "%2.1f" br :: String
    blueBeltStr   = printf "%2.1f" bb :: String
    beltsStr = printf "%8s%8s%8s" yellowBeltStr redBeltStr blueBeltStr :: String

sumTuple3 :: (Num a) => [(a,a,a)] -> (a,a,a)
sumTuple3 xs = (sum x, sum y, sum z)
  where (x,y,z) = unzip3 xs

h = unzip3

main :: IO ()
main = do
    printf "To produce %f %ss/second:\n" desiredItemsPerSecond itemName
    printf "\n"
    pairs <- return ((ceiling (numFactories/2.0)) :: Int)
    printf "  Number of Factories: %f (%d pairs)\n" numFactories pairs
    printf "\n"
    printf "  Total input of                  Quantity   Yellow     Red    Blue\n"
    printf "  -----------------------------------------------------------------\n"
    rates <- return (map depPerSecond . map snd $ ingredients)
    belts <- return (map toBelts rates)
    names <- return (map fst ingredients)
    putStr $ unlines $ map (printf "  %s") $ map depStr $ zip3 names rates belts
    printf "  -----------------------------------------------------------------\n"
    putStr $ printf "  %s\n" $ depStr ("total", -1, (sumTuple3 belts))
    printf "\n"
