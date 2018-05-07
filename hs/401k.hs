#!/usr/bin/env stack
-- stack --resolver lts-9.21 --install-ghc runghc

existing = 45000  -- current 401k balance

age      = 36     -- current age
retAge   = 66     -- age of withdrawal (must be >= 60)
death    = 90     -- age of death

income   = 146000 -- annual income
contrib  = 0.10   -- employee contribution
match    = 0.50   -- percent matched by employer

growth   = 0.06   -- estimated growth of 401k investment plan
tax      = 0.30   -- tax taken out at withdrawal at retirement age

afterTaxFuture   = (1.0-tax) * income * contrib * (1.0+match) * (sum $ map ((1.0+growth)**) $ [0..(retAge-age)])
afterTaxExisting = (1.0-tax) * existing * ((1.0+growth)**(retAge-age))

afterTaxTotal = afterTaxExisting + afterTaxFuture
perYear       = afterTaxTotal/(death-retAge)
kPerYear      = round (perYear/1000.0)

main :: IO ()
main = putStrLn $ "After-Tax income from 401k: " ++ show kPerYear ++ "k/year of retirement"
