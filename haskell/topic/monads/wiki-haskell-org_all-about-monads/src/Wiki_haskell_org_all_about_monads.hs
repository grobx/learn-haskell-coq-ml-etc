{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# OPTIONS_GHC -fno-warn-type-defaults      #-}
{-# OPTIONS_GHC -fno-warn-unused-do-bind     #-}

-- FlexibleContexts for getRan'
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports    #-}
{-
:set -XOverloadedStrings
-}
{-
Created       : 2015 Aug 15 (Sat) 09:41:08 by Harold Carr.
Last Modified : 2018 Jun 17 (Sun) 11:33:26 by Harold Carr.

https://wiki.haskell.org/All_About_Monads
http://web.archive.org/web/20061211101052/http://www.nomaware.com/monads/html/index.html
-}

module Wiki_haskell_org_all_about_monads
where

import           Control.Arrow      ((&&&))
import           Control.Monad      (MonadPlus (..), ap, foldM, guard,
                                     liftM2, mapM, mapM_, msum, sequence,
                                     sequence_, zipWithM, zipWithM_)
import "mtl"     Control.Monad.Cont
import           Control.Monad.Except
import           Control.Monad.Plus (mfromMaybe)
import "mtl"     Control.Monad.Reader
import "mtl"     Control.Monad.State
import "mtl"     Control.Monad.Writer
import           Data.Char          (chr, digitToInt, isAlpha, isDigit, isHexDigit, isSpace)
import qualified Data.Map     as Map
import           Data.Maybe         (fromJust, mapMaybe)
import           System.Random      (Random(..), StdGen, getStdGen, mkStdGen, randomR)
import qualified Test.HUnit         as TT
import qualified Test.HUnit.Util    as U
import           X_02_example       hiding (parent)

{-# ANN module ("HLint: ignore Reduce duplication" :: String) #-}
{-# ANN module ("HLint: ignore Use const" :: String) #-}
{-# ANN module ("HLint: ignore Redundant lambda" :: String) #-}
{-# ANN module ("HLint: ignore Redundant bracket" :: String) #-}
{-# ANN module ("HLint: ignore Collapse lambdas" :: String) #-}
{-# ANN module ("HLint: ignore Avoid lambda" :: String) #-}


{-
------------------------------------------------------------------------------
1.1 What is a monad?

Monads
- sequential computations
- determine how combined computations form a new computation
- frees programmer coding combination manually

1.2 Why should I make the effort to understand monads?

Monads : structuring functional programs
- Modularity
  - computations composed from other computations
  - separate combination strategy from computations
- Flexibility
j  - programs more adaptable than programs written without monads
  - monad puts computational strategy in single place
    (instead of distributed in entire program)
- Isolation
  - imperative-style structures isolated from main program.

------------------------------------------------------------------------------
2 Meet the Monads

-- the type of monad m
data m a = ...

-- return is a type constructor that creates monad instances
return :: a -> m a

-- combines a monad instance 'm a' with a computation 'a -> m b'
-- to produce another monad instance 'm b'
(>>=) :: m a -> (a -> m b) -> m b

Container analogy
- type constructor 'm' is container that can hold different values 'a'
- 'm a' is container holding value of type 'a'
- 'return' puts value into monad container
- >>= takes value from monad container, passes it a function
  to produce a monad container containing a new value, possibly of a different type
  - binding function can implement strategy for combining computations in the monad

2.3 An example
-}

maternalGF1 :: Sheep -> Maybe Sheep
maternalGF1 s =
  case mother s of
    Nothing -> Nothing
    Just m  -> father m

momsPaternalGF1 :: Sheep -> Maybe Sheep
momsPaternalGF1 s =
  case mother s of
    Nothing -> Nothing
    Just m  -> case father m of
                 Nothing -> Nothing
                 Just gf -> father gf

mom1  = U.t "mom1"  (show (mother          breedSheep))  (show (Just "Molly"))
dad1  = U.t "dad1"  (show (father          breedSheep))  (show (Nothing::Maybe Sheep))
mgf1  = U.t "mgf1"  (show (maternalGF1     breedSheep))  (show (Just "Roger"))
mpgf1 = U.t "mpgf1" (show (momsPaternalGF1 breedSheep))  (show (Just "Kronos"))

{-
2.4 List is also a monad

List monad enables computations that can return 0, 1, or more values.

(>>=)     :: Monad m => m a -> (a -> m b) -> m b
(=<<)     :: Monad m => (a -> m b) -> m a -> m b
concatMap ::            (a -> [b]) -> [a] -> [b]
-}

listEx = U.t "listEx"
         ([1,2,3] >>= \x -> [x + 1])
          [2,3,4]

{-
2.5 Summary

Maybe monad
- combining computations that may not return values
[] monad
- combining computations that can return 0, 1, or more values

------------------------------------------------------------------------------
3.2 The Monad class

class Monad m where
    (>>=)  :: m a -> (a -> m b) -> m b
    return :: a -> m a

3.3 Example continued

instance Monad Maybe where
    Nothing  >>= f = Nothing
    (Just x) >>= f = f x
    return         = Just

-}

maternalGF2 :: Sheep -> Maybe Sheep
maternalGF2 s = mother s >>= father

dadsMaternalGF2 :: Sheep -> Maybe Sheep
dadsMaternalGF2 s = father s >>= mother >>= mother

maternalGF3 :: Sheep -> [Sheep]
maternalGF3 s = mfromMaybe (mother s) >>= mfromMaybe . father

dadsMaternalGF3 :: Sheep -> [Sheep]
dadsMaternalGF3 s = mfromMaybe (father s) >>= mfromMaybe . mother >>= mfromMaybe . mother

mgf2  = U.t "mgf2"  (show (maternalGF2     breedSheep))       (show $ Just "Roger")
dmgf2 = U.t "dmgf2" (show (dadsMaternalGF2 breedSheep))       (show (Nothing::Maybe Sheep))
mgf3  = U.t "mgf3"  (show (maternalGF3     breedSheep))       (show ["Roger"])
dmgf3 = U.t "dmgf3" (show (dadsMaternalGF3 breedSheep))       (show ([]::[String]))

{-
3.4 Do notation

'do' notation resembles imperative language
- computation built from sequence of computations

------------------------------------------------------------------------------
4 The monad laws

Not enforced by Haskell compiler: programmer must ensure.
Ensure semantics of do-notation consistent.
- (return x) >>= f == f x
  - return is left-identity for >>=
- m >>= return     == m
  - return is right-identity for >>=
- (m >>= f) >>= g  == m >>= (\x -> f x >>= g)
- >>= is associative

4.3 No way out

No way to get values out of monad as defined in Monad class (on purpose).
Specific monads might provide such functions (e.g., 'fromJust' or pattern-matching '(Just x)')

One-way monads
- values enter monad via 'return'
- computations performed within monad via '>>='
- but can't get values out of monad.
  - e.g., IO monad
- enables "side-effects" in monadic operations but prevent them escaping to rest of program

Common pattern
- represent monadic values as functions
- when value of monadic computation required, "run" monad to provide the answer.

4.4 Zero and Plus

MonadPlus

Some monads obey additional laws
- mzero >>= f         == mzero
- m >>= (\x -> mzero) == mzero
- mzero `mplus` m     == m
- m `mplus` mzero     == m
(i.e., mzero/0, mplus/+, >>=/×)

class (Monad m) => MonadPlus m where
    mzero :: m a
    mplus :: m a -> m a -> m a

instance MonadPlus Maybe where
    mzero             = Nothing
    Nothing `mplus` x = x
    x `mplus` _       = x

Identifies Nothing as the zero value.
Adding two Maybe values gives first value that is not Nothing

[] monad : mzero/empty-list, mplus/++

'mplus' combines two monadic values into single monadic value
-}

parent :: Sheep -> [Sheep]
parent s = mfromMaybe (mother s) `mplus` mfromMaybe (father s)

prnt1 = U.t "prnt1" (show (parent breedSheep))                     (show ["Molly"])
prnt2 = U.t "prnt1" (show (parent (head (parent breedSheep))))     (show ["Holly","Roger"])

{-
------------------------------------------------------------------------------
5 Exercises

./X_02_example.hs

------------------------------------------------------------------------------
6 Monad support in Haskell

6.1.2 The sequencing functions

-- given list of monadic computations
-- executes each one in turn
-- returns list of results
-- If any computation fails, then the whole function fails:
sequence :: Monad m => [m a] -> m [a]
sequence = foldr mcons (return [])
  where mcons x acc = x >>= \x' -> acc >>= \acc' -> return (x':acc')
-}

seqExM = U.t "seqExM" (sequence [Just 1,  Just 2])
                      (Just [1,2])
seqExL = U.t "seqExL" (sequence [[    1], [    2]])
                           [[1,2]]
seqExF = U.t "seqExF" (sequence [Just 1,  Just 2, Nothing, Just 3])
                      Nothing

{-          mcons
           /     \
          1       mcons
                 /     \
                2       return []

-- same behavior but does not return list of results
-- useful for side-effects
sequence_ :: Monad m => [m a] -> m ()
sequence_ = foldr (>>) (return ())
-}

seq_ExM :: IO ()
seq_ExM = sequence_ [print 1, print 2]

{-
            >>
           /  \
    print 1    >>
              /  \
       print 2    return ()
-}

{-
6.1.3 The mapping functions

-- maps monadic computation over list of values
-- returns list of results
mapM  :: Monad m => (a -> m b) -> [a] -> m [b]
mapM  f as = sequence  (map f as)

mapM_ :: Monad m => (a -> m b) -> [a] -> m ()
mapM_ f as = sequence_ (map f as)

Example:

putString :: [Char] -> IO ()
putString s = mapM_ putChar s

Common pattern: mapM used in a do block, similar to map on lists.

-- compare non-monadic and monadic signatures
map  ::            (a ->   b) -> [a] ->   [b]
mapM :: Monad m => (a -> m b) -> [a] -> m [b]
-}

mapMExM = U.t "mapMExM" (mapM Just [1,2,3])
                        (Just [1,2,3])

mapM_ExM :: IO ()
mapM_ExM = mapM_ print [1,2,3]

{-
6.2.2 Monadic versions of list functions

foldM : monadic foldl : monadic computations left-to-right

foldM :: (Monad m) => (a -> b -> m a) -> a -> [b] -> m a
foldM f a []     = return a
foldM f a (x:xs) = f a x >>= \y -> foldM f y xs

easier to understand pseudo-Haskell:

foldM f a1 [x1,x2,...,xn] = do a2 <- f a1 x1
                               a3 <- f a2 x2
                               ...
                               f an xn

If right-to-left needed: reverse input before calling foldM.

Example 3:
-}

-- TODO : use this

-- traceFamily :: Sheep -> [ Sheep -> Maybe Sheep ] -> Maybe Sheep
traceFamily :: Monad m => Sheep -> [ Sheep -> m Sheep ] -> m Sheep
traceFamily = foldM getParent
  where getParent s f = f s

fm  = U.t "fm"  (show (traceFamily breedSheep [father, mother]))
                (show (Nothing::Maybe Sheep))
mff = U.t "mff" (show (traceFamily breedSheep [mother, father, father]))
                (show (Just "Kronos"))
mmm = U.t "mmm" (show (traceFamily breedSheep [mother,mother,mother]))
                (show (Just "Eve"))

{-
Typical use of foldM is within a do block.
See example4.hs
    program builds dictionary from entries in all files named on the command line

-- like list filter, but inside of a monad.
filterM :: Monad m => (a -> m Bool) -> [a] -> m [a]
filterM p []     = return []
filterM p (x:xs) = do b  <- p x
                      ys <- filterM p xs
                      return (if b then (x:ys) else ys)

See example5.hs

-- zipWithM : monadic zipWith function on lists
zipWithM  :: (Monad m) => (a -> b -> m c) -> [a] -> [b] -> m [c]
zipWithM  f xs ys = sequence  (zipWith f xs ys)

-- discards output
zipWithM_ :: (Monad m) => (a -> b -> m c) -> [a] -> [b] -> m ()
zipWithM_ f xs ys = sequence_ (zipWith f xs ys)

-}

zipWithMHC = U.t "zipWithMHC"
             (zipWithM  (curry Just)  [1,2,3] "abc")
             (Just [(1,'a'),(2,'b'),(3,'c')])

zipWithM_HC :: IO ()
zipWithM_HC = zipWithM_ (curry print) [1,2,3] ("abc"::String)

{-
6.2.3 Conditional monadic computations

when   :: (Monad m) => Bool -> m () -> m ()
when   p s = if p then s else return ()

unless :: (Monad m) => Bool -> m () -> m ()
unless p s = when (not p) s

6.2.4 ap and the lifting functions

Lifting : converts a non-monadic function to work monadic values.

Use: operating on monad values outside of a do block.
Use: cleaner code in a do block.

liftM  :: (Monad m) => (a -> b)      -> (m a -> m b)
liftM  f = \a -> do
    a' <- a
    return (f a')

liftM2 :: (Monad m) => (a -> b -> c) -> (m a -> m b -> m c)
liftM2 f = \a b ->
    a' <- a
    b' <- b
    return (f a' b')

up to liftM5 defined in Monad module.

example 6: more concise code:
-}

-- converts "Smith, John" into "John Smith"
swapNames :: String -> String
swapNames s = let (ln,fn) = break (==',') s
              in dropWhile isSpace (tail fn) ++ " " ++ ln

getName :: String -> Maybe String
getName name0 = do
  let db = [("John", "Smith, John"), ("Mike", "Caine, Michael")]
  fmap swapNames (lookup name0 db)

{- Without using the liftM operation, we would have had to do something
   that is less succinct, like this:

getName name = do let db = [("John", "Smith, John"), ("Mike", "Caine, Michael")]
                  tempName <- lookup name db
	          return (swapNames tempName)

Difference even greater when lifting functions with more args.
-}

gn = U.t "gn" [   getName "John",      getName "Mike", getName "Harold"]
              [Just "John Smith",Just "Michael Caine", Nothing         ]

{-
Lifting enables concise higher-order functions.
-}

-- returns list containing result of folding the given binary operator
-- through all combinations of elements of the given lists.
allCombinations :: (a -> a -> a) -> [[a]] -> [a]
allCombinations  _ []     = []
allCombinations fn (l:ls) = foldl (liftM2 fn) l ls

-- e.g., allCombinations (+) [[0,1],[1,2,3]]
--   => [0+1,0+2,0+3,1+1,1+2,1+3], or [1,2,3,2,3,4]
--       allCombinations (*) [[0,1],[1,2],[3,5]] would be
--   => [0*1*3,0*1*5,0*2*3,0*2*5,1*1*3,1*1*5,1*2*3,1*2*5], or [0,0,0,0,3,5,6,10]

ac1 = U.t "ac1" (allCombinations (+) [[0,1],[1,2,3]])
                [1,2,3,2,3,4]
ac2 = U.t "ac2" (allCombinations (*) [[0,1],[1,2],[3,5]])
                [0,0,0,0,3,5,6,10]
ac3 = U.t "ac3" (allCombinations div [[100, 45, 365], [3, 5], [2, 4], [2]])
                [8,4,5,2,3,1,2,1,30,15,18,9]

{-
related function : 'ap' : sometimes more lift.

liftM  :: (Monad m) =>   (a -> b) -> (m a -> m b) -- for comparison
ap     :: (Monad m) => m (a -> b) -> (m a -> m b)
ap      = liftM2 ($)

Note:      liftM2 f      x      y
           return f `ap` x `ap` y

and so on for functions of more arguments.

Useful when working with higher-order functions and monads.

Effect of ap depends on specific monad.
-}

apEx1 = U.t "apEx1" ([(*2),(+3)] `ap` [0,1,2])        [0,2,4,3,4,5]
apEx2 = U.t "apEx2" (Just (*2)   `ap` Just 3)         (Just 6)

-- lookup commands
-- fold ap into resulting command list
-- to compute a result
apEx val cmds0 =
    let fns  = [("double" ,    (2*))
               ,("halve"  ,(`div`2))
               ,("square" , \x->x*x)
               ,("negate" ,  negate)
               ,("incr"   ,    (+1))
               ,("decr"   , (+(-1)))
               ]
        cmds = map (`lookup` fns) (words cmds0)
     in foldl (flip ap) (Just val) cmds

apEx3 = U.t "apEx3" (apEx 2 "double square decr negate")
                    (Just (-15))

{-
6.2.5 Functions for use with MonadPlus

Used with monads that have a zero and a plus

- like sum function on lists of integers
msum :: MonadPlus m => [m a] -> m a
msum xs = foldr mplus mzero xs

List monad: msum==concat
Maybe monad: msum==returns the first non-Nothing value from a list
-}

type Variable = String
type Value = String
type EnvironmentStack = [[(Variable,Value)]]

-- leverages lazyness : the map only does first element, then feeds results to msum
--                      next element only looked at if first results in Nothing
lookupVar :: Variable -> EnvironmentStack -> Maybe Value
lookupVar var stack = msum $ map (lookup var) stack

{-
instead of:

lookupVar :: Variable -> EnvironmentStack -> Maybe Value
lookupVar var []     = Nothing
lookupVar var (e:es) = let val = lookup var e
                       in maybe (lookupVar var es) Just val
-}

ms1 = U.t "ms1" (lookupVar "depth" [[("name","test"),("depth","2")]
                                   ,[("depth","1")]])
                (Just "2")
ms2 = U.t "ms2" (lookupVar "width" [[("name","test"),("depth","2")]
                                   ,[("depth","1")]])
                Nothing
ms3 = U.t "ms3" (lookupVar "var2"  [[("var1","value1"),("var2","value2*")]
                                   ,[("var2","value2"),("var3","value3")]])
                (Just "value2*")

{-
guard :: MonadPlus m => Bool -> m ()
guard p = if p then return () else mzero

Recall MonadPlus law : mzero >>= f == mzero.
Placing guard in monad sequence will force any execution in which guard is False to be mzero.
Like guard predicates in list comprehensions cause values that fail to become [].
-}

data Record = Rec {nameR::String, age::Int} deriving (Eq, Show)
type DB = [Record]

-- return records less than specified age.
-- Uses guard to eliminate records at or over limit.
-- Real code would be clearer using a filter except guard more useful when filter is complex.
-- mapMaybe : eliminates Nothing/mzero from results
-- guard returning mzero in causes do to skip 'return r'
getYoungerThan :: Int -> DB -> [Record]
getYoungerThan limit = mapMaybe (\r -> do { guard (age r < limit); return r })

gytDB = [Rec "Marge" 37, Rec "Homer" 38, Rec "Bart" 11, Rec "Lisa" 8, Rec "Maggie" 2]

gyt1 = U.t "gyt1" (getYoungerThan  3 gytDB)
                  [Rec {nameR = "Maggie", age = 2}]
gyt2 = U.t "gyt2" (getYoungerThan 38 gytDB)
                  [Rec {nameR = "Marge", age = 37}
                  ,Rec {nameR = "Bart", age = 11}
                  ,Rec {nameR = "Lisa", age = 8}
                  ,Rec {nameR = "Maggie", age = 2}
                  ]

{-
------------------------------------------------------------------------------
7 Introduction

Monad
- Computation
- Combination strategy (>>= behavoir)

Identity
- N/A — Used with monad transformers
- bound function applied to input value

Maybe
- computations with 0 or 1 result
- Nothing input gives Nothing output
- Just x input uses x as input to bound function

Error
- computations that can fail (e.g., "throw" exceptions)
- binding passes failure info on without executing bound function
  or uses successful values as input to bound function

[] (List)
- computations that can return multiple possible results
- Maps bound function across input list, concatenates resulting lists

IO
- Computations which perform I/O
- Sequential execution of I/O actions in the order of binding.

State
- Computations which maintain state
- bound function applied to input value
  produces state transition function that is applied to input state

Reader
- Computations that read from shared environment
- bound function applied to input using the same environment

Writer
- Computations that write data in addition to computing values
- Written data maintained separately from values.
  bound function applied to input
  anything it writes is appended to write data stream

Cont
- Computations that can be interrupted and restarted
- bound function inserted into continuation chain

------------------------------------------------------------------------------
8 The Identity monad

Computation: function application
Binding: bound function applied to input: Identity x >>= f == Identity (f x)
Use:  Monads derived from monad transformers applied to Identity monad.
Zero/plus: None.
Example: Identity a

8.2 Motivation

Does not embody a computation.
Purpose is its role in monad transformers:
- a monad transformer applied to Identity yields a non-transformer version of that monad.

8.3 Definition

newtype Identity a = Identity { runIdentity :: a }

instance Monad Identity where
    return a           = Identity a
    (Identity x) >>= f = f x

'runIdentity' follows style of monad definition that represents monad values as computations:
- a monadic computation built up using monadic operators
- value of computation extracted using run*

8.4 Example

-- derive the State monad using the StateT monad transformer
type State s a = StateT s Identity a

------------------------------------------------------------------------------
9 The Maybe monad

Computation: may return Nothing
Binding: Nothing bypasses bound function; Just given as input to bound function.
Use: sequences of computations that may return Nothing (e.g., database queries, dictionary lookups)
Zero/plus: Nothing/zero. Plus returns first non-Nothing value or Nothing if both Nothing.
Example: Maybe a

9.2 Motivation

combining a chain of Maybe computations: end chain early if any produces Nothing as output.

9.3 Definition

data Maybe a = Nothing | Just a

instance Monad Maybe where
    return         = Just
    fail           = Nothing
    Nothing  >>= f = Nothing
    (Just x) >>= f = f x

instance MonadPlus Maybe where
    mzero             = Nothing
    Nothing `mplus` x = x
    x `mplus` _       = x

9.4 Example

Combining dictionary lookups.

Given dictionaries : full name     -> email address
                     nicknames     -> email address
                     email address -> email preferences
find email prefs given full or nick name.
-}

type EmailAddr = String
data MailPref = HTML | Plain deriving (Eq, Show)

data MailSystem = MS { fullNameDB :: [(String,EmailAddr)],
                       nickNameDB :: [(String,EmailAddr)],
                       prefsDB    :: [(EmailAddr,MailPref)] }

data UserInfo = User { msName :: String,
                       nick   :: String,
                       email  :: EmailAddr,
                       prefs  :: MailPref }

makeMailSystem :: [UserInfo] -> MailSystem
makeMailSystem users = let fullLst = map (msName &&& email) users
                           nickLst = map (nick   &&& email) users
                           prefLst = map (email  &&& prefs) users
                       in MS fullLst nickLst prefLst

-- skips next steps if any returns Nothing
getMailPrefs :: MailSystem -> String -> Maybe MailPref
getMailPrefs sys name0 = do
    addr <- lookup name0 (fullNameDB sys) `mplus` lookup name0 (nickNameDB sys)
    lookup addr (prefsDB sys)

mailSystem = makeMailSystem
                 [ User "Bill Gates"      "billy"       "billg@microsoft.com" HTML
                 , User "Bill Clinton"    "slick willy" "bill@hope.ar.us"     Plain
                 , User "Michael Jackson" "jacko"       "mj@wonderland.org"   HTML
                 ]

mail1 = U.t "mail1" (getMailPrefs mailSystem "billy")
                    (Just HTML)
mail2 = U.t "mail2" (getMailPrefs mailSystem "Bill Gates")
                    (Just HTML)
mail3 = U.t "mail3" (getMailPrefs mailSystem "Bill Clinton")
                    (Just Plain)
mail4 = U.t "mail4" (getMailPrefs mailSystem "foo")
                    Nothing

{-
------------------------------------------------------------------------------
10 The Control.Monad.Except monad

10.1 Overview

Computation: computations which may fail or throw exceptions
Binding: Failure values bypass bound function. Success values are inputs to bound function.
Use: Sequences of functions that may fail.
Zero/plus: Zero/empty error. Plus executes 2nd arg if first fails.
Example type: Either String a

10.2 Motivation

Except monad (aka Exception monad) combining computations that may
throw exceptions by bypassing bound functions from point of exception
to point handled.

MonadError parameterized error type of error and monad type constructor.
Common: Either String as monad type constructor. In this case (and others)
the resulting monad is already defined as an instance of the MonadError class.

Can also define custom error type and/or use monad type constructor other
than Either String or Either IOError. These cases need instance definitions of
Error and/or MonadError classes.

10.3 Definition

uses multi-parameter type classes and funDeps

newtype ExceptT e m a :: * -> (* -> *) -> * -> *

type Except e = ExceptT e Identity

class (Monad m) => MonadError e m | m -> e where
    throwError :: e -> m a
    catchError :: m a -> (e -> m a) -> m a

throwError used in monadic computation to begin exception processing
catchError provides a handler function to handle previous errors and return to normal execution.

Common idiom:

do { action1; action2; action3 } `catchError` handler

Handler and do-block must have same return type.

10.4 Example

Custom Error with ErrorMonad's throwError and catchError.

Parse hexadecimal numbers.
Throws exception on invalid character.
Error records location of error.
-}

data ParseError = Err {location::Int, reason::String}

-- Monad type constructor
-- - failure : Left ParseError
-- - success : Right a
type ParseMonad = Either ParseError

-- idx is current location in parse
parseHexDigit :: Char -> Int -> ParseMonad Integer
parseHexDigit c idx = if isHexDigit c then
                        return (toInteger (digitToInt c))
                      else
                        throwError (Err idx ("Invalid character '" ++ [c] ++ "'"))

-- idx is current location in parse
parseHex :: String -> ParseMonad Integer
parseHex s = parseHex' s 0 1
  where parseHex' []      val _   = return val
        parseHex' (c:cs)  val idx = do d <- parseHexDigit c idx
                                       parseHex' cs ((val * 16) + d) (idx + 1)

toString :: Integer -> ParseMonad String
toString n = return $ show n

-- convert hex String rep to decimal String rep
convert :: String -> String
convert s = let (Right str) = do { n <- parseHex s; toString n } `catchError` printError
            in str
  where printError e = return $ "At index " ++ show (location e) ++ ":" ++ reason e

p1 = U.t "p1" (convert "FF")      "255"
p2 = U.t "p2" (convert "FFFF")    "65535"
p3 = U.t "p3" (convert "FFFFxF")  "At index 5:Invalid character 'x'"

{-
------------------------------------------------------------------------------
11 The List monad

Computation: return 0, 1, or more results.
Binding: bound function applied to all inputs, resulting lists concatenated
Use: Sequences of non-deterministic operations. Parsing ambiguous grammars is a common example.
Zero/plus: []/zero ++/plus
Example: [a]

11.2 Motivation

Useful when computations must deal with ambiguity.
Enables all possibilities to be explored until ambiguity resolved.

11.3 Definition

instance Monad [] where
    m >>= f  = concatMap f m
    return x = [x]
    fail s   = []

instance MonadPlus [] where
    mzero = []
    mplus = (++)

11.4 Example

Parsing ambiguous grammars.

Parse data into hex, decimal or alphanumeric words.
Hex overlaps decimal and alphanumeric: ambiguous grammar.
- "dead" is both a valid hex value and a word
- "10" is both a decimal value of 10 and a hex value of 16
-}

data Parsed = Digit Integer | Hex Integer | Word String deriving (Eq, Show)

parseCommon :: (Char -> Bool) -> Char -> Parsed -> [Parsed]
parseCommon test0 c ret = if test0 c then return ret else mzero

-- try to add char to parsed rep of hex digit
parseHexDigt :: Parsed -> Char -> [Parsed]
parseHexDigt (Hex   n) c = parseCommon isHexDigit c (Hex ((n*16) + toInteger (digitToInt c)))
parseHexDigt _         _ = mzero

-- try to add char to parsed rep of decimal digit
parseDigit   :: Parsed -> Char -> [Parsed]
parseDigit   (Digit n) c = parseCommon isDigit    c (Digit ((n*10) + toInteger (digitToInt c)))
parseDigit   _         _ = mzero

-- try to add a char to parsed rep of word
parseWord    :: Parsed -> Char -> [Parsed]
parseWord    (Word  s) c = parseCommon isAlpha    c (Word (s ++ [c]))
parseWord _            _ = mzero

-- tries to parse input as hex, decimal and word
-- result is list of possible parses
parse :: Parsed -> Char -> [Parsed]
parse p c = parseHexDigt p c `mplus` parseDigit p c `mplus` parseWord p c

-- parse an entire String and return list of possible parsed values
parseArg :: String -> [Parsed]
parseArg s = do
  init0 <- return (Hex 0) `mplus` return (Digit 0) `mplus` return (Word "")
  foldM parse init0 s

sr1 = U.t "sr1" (parseArg "dead") [Hex 57005,Word "dead"]
sr2 = U.t "sr2" (parseArg   "10") [Hex 16,Digit 10]
sr3 = U.t "sr3" (parseArg  "foo") [Word "foo"]

{-
------------------------------------------------------------------------------
12 The IO monad

Computation: perform I/O
Binding: I/O actions executed in order in which they are bound.
         Failures throw I/O errors which can be caught and handled.
Use: I/O
Zero/plus: None.
Example: IO a

12.2 Motivation

I/O not pure.  IO monad confines I/O computations

12.3 Definition

Definition platform-specific.
No data constructors are exported and no functions to remove data from IO monad.
IO monad is a one-way monad: essential to ensuring safety.
Isolates side-effects and non-referentially transparent actions within
 imperative-style computations of the IO monad.

Monadic values usually known as computations.
Balues in IO monad are called I/O actions.

Functions exported from IO module do not perform I/O.
They return I/O actions that describe an I/O operation to be performed.

I/O actions combined within IO monad (in a purely functional manner)
to create more complex I/O actions, resulting in final I/O action that is main value of program.

IO type constructor is a Monad class and MonadError class.

instance Monad IO where
    return a = ...   -- function from a -> IO a
    m >>= k  = ...   -- executes the I/O action m and binds the value to k's input
    fail s   = ioError (userError s)

data IOError = ...

ioError :: IOError -> IO a
ioError = ...

userError :: String -> IOError
userError = ...

catch :: IO a -> (IOError -> IO a) -> IO a
catch = ...

try :: IO a -> IO (Either IOError a)
try f = catch (do r <- f
                  return (Right r))
              (return . Left)

instance Error IOError where
  ...

instance MonadError IO where
    throwError = ioError
    catchError = catch

IO exports 'try' that executes I/O action
- returns Right on success
- Left IOError if I/O error caught

12.4 Example

Partial impl of "tr"
-}

-- translate char in set1 to corresponding char in set2
translate :: String -> String -> Char -> Char
translate []     _      c = c
translate (x:xs) []     c = if x == c then ' ' else translate xs []  c
translate (x:xs) [y]    c = if x == c then  y  else translate xs [y] c
translate (x:xs) (y:ys) c = if x == c then  y  else translate xs ys  c

-- translate an entire string           this
translateString :: String -> String -> String -> String
translateString set1 set2 = map (translate set1 set2)

usage :: IOError -> IO ()
usage _ = do
  putStrLn "Usage: ex14 set1 set2"
  putStrLn "Translates characters in set1 on stdin to the corresponding"
  putStrLn "characters from set2 and writes the translation to stdout."

-- translates stdin to stdout based on commandline arguments
-- main2
-- abcdefghijklmnopqrstuvwxyz
-- ABCDEFGHIJKLMNOPQRSTUVWXYZ
-- thegeekstuff
-- => THEGEEKSTUFF
main2 :: IO ()
main2 = (do putStr "Enter set1: "
            set1 <- getLine
            putStr "Enter set2: "
            set2 <- getLine
            putStr "Enter contents: "
            contents <- getLine
            putStrLn $ translateString set1 set2 contents)
        `catchError` usage

{-
------------------------------------------------------------------------------
13 The State monad

Computation: maintain state.
Binding: state parameter threaded through sequence of bound functions
         so that same state value is never used twice, giving the illusion of in-place update.
Use: sequences of operations that require a shared state.
Zero/plus: None.
Example:  State st a

13.2 Motivation

Pure language cannot update in place: violates referential transparency.
Instead, simulate state.
-}

data RandomResults = RR Int Char Int deriving (Eq, Show)

-- Without state, thread by hand:
makeRandomValue :: StdGen -> (RandomResults, StdGen)
makeRandomValue g = let (n,g1) = randomR (1  ,1000) g
                        (c,g2) = randomR ('a', 'z') g1
                        (m,g3) = randomR (-n ,   n) g2
                    in (RR n c m, g3)

{-
State monad puts threading of state inside (>>=).

13.3 Definition

- State monad values are transition funs from initial state to (value,newState) pair.
- State s a
  - value of type a
  - inside the State monad with state of type s.
newtype State s a = State { runState :: (s -> (a,s)) }

- return : creates state transition fun that sets value but leaves state unchanged.
- bind   : creates state transition fun that applies right arg to val
           and new state from its left-hand argument.
instance Monad (State s) where
    return a        = State $ \s -> (a,s)
    (State x) >>= f = State $ \s -> let (v,s') = x s in runState (f v) s'

instance MonadState (State s) s where
--  get  :: m s
    get   = State $ \s -> (s,s)    -- retrieves state by copying it as the value
--  put  :: s -> m ()
    put s = State $ \_ -> ((),s)   -- sets state of monad and does not yield a value
--  gets                           -- retrieves function of the state

13.4 Example

thread random generator state through multiple calls to generation function.
-}

-- bounds random value
getRan :: (Random a) => (a,a) -> State StdGen a
getRan bounds = do g      <- get
                   (x,g') <- return $ randomR bounds g
                   put g'
                   return x

-- State monad with StdGen as state, no manually threading of random generator states
makeRandomValueST :: StdGen -> (RandomResults, StdGen)
makeRandomValueST = runState (do n <- getRan (1  ,1000)
                                 c <- getRan ('a', 'z')
                                 m <- getRan (-n ,   n)
                                 return (RR n c m))

-- showing implementations equivalent
rg = do
    g <- getStdGen
    print $ fst $ makeRandomValue   g
    print $ fst $ makeRandomValueST g

-- (runState $ getRan (1,10)) gen
gen = mkStdGen 1000
ranT = U.tt "ranT"
       (map fst [makeRandomValueST gen
                ,runState
                  (do n <- getRan (1  ,1000)
                      c <- getRan ('a', 'z')
                      m <- getRan (-n ,   n)
                      return (RR n c m)) gen
                ,runState
                      (getRan (1, 1000)   >>= \n ->
                       getRan ('a', 'z')  >>= \c ->
                       getRan (- n, n)    >>= \m ->
                       return (RR n c m)) gen
                ])
       (RR 884 'h' 411)

-- getRan' :: (Random a) => (a, a) -> State StdGen a
getRan' bounds = get                       >>= \g       ->
                 return $ randomR bounds g >>= \(x, g') ->
                 put g'                    >>
                 return x
{-
makeRandomValueST' :: StdGen -> (RandomResults, StdGen)
makeRandomValueST' = runState
                      (getRan' (1, 1000)   >>= \n ->
                       getRan' ('a', 'z')  >>= \c ->
                       getRan' (- n, n)    >>= \m ->
                       return  (RR n c m))

rg' = getStdGen                            >>= \g ->
      print $ fst $ makeRandomValue   g    >>
      print $ fst $ makeRandomValueST g
-}
-- HC example : Same structure but simpler state

inc :: Int -> State Int Char
inc x = do
    i <- get
    put (i + x)
    return (chr i)

incB0 :: Int -> State Int Char
incB0 x =
    get         >>= \i ->
    put (i + x) >>
    return (chr i)

incB1 :: Int -> State Int Char
incB1 x =
  state (\g -> (    g,     g)) >>= \i ->
  state (\_ -> (   (), i + x)) >>
  state (\s -> (chr i,     s))

incB2 :: Int -> State Int Char
incB2 x =
  state $ \s ->
    let (v,s') = (\g -> (g, g)) s
    in runState ((\i -> state $ \s2 ->
                          let (v',s'') = (\_ -> ((), i + x)) s2
                          in runState ((\_ -> state (\r -> (chr i, r))) v') s'')
                 v) s'

incB3 :: Int -> (Int -> (Char, Int))
incB3 x =
    \s ->
      let (v,s') = (\g -> (g, g)) s
      in ((\i -> \s'' -> let (v',s''') = (\_ -> ((), i + x)) s''
                       in ((\_ -> (\r -> (chr i, r))) v') s''')
          v) s'

-- COMPLETELY REDUCED
incB4 :: Int -> (Int -> (Char, Int))
incB4 x =
    \s0 ->
      ((\(i, s) -> ((\(_v2,r) -> (chr i, r))   -- return
                    ((\_ -> ((), i + x)) s)))  -- put
       ((\g -> (g, g)) s0))                    -- get

incer :: Int -> ((Char,Char,Char), Int)
incer = runState
    (do i1 <- inc 10
        i2 <- inc 40
        i3 <- inc 8
        return (i1, i2, i3))

incerB :: Int -> ((Char,Char,Char), Int)
incerB = runState
       (incB0 10 >>= \i1 ->
        incB0 40 >>= \i2 ->
        incB0 8  >>= \i3 ->
        return (i1, i2, i3))

incer1 :: Int -> ((Char,Char,Char), Int)
incer1 = runState (do i1 <- ((\x -> do
                                   -- i <- get
                                   i <- state (\s -> (s, s))
                                   -- put (i + x)
                                   state (\_ -> ((), i + x))
                                   -- return i
                                   state (\s -> (chr i,s))
                             ) :: Int -> State Int Char) 10
                      i2 <- inc 40
                      i3 <- inc 8
                      return (i1, i2, i3))

incerB1 :: Int -> ((Char,Char,Char), Int)
incerB1 = runState (((\x ->
                       state (\s -> (s, s))      >>= \i ->  -- get
                       state (\_ -> ((), i + x)) >>         -- put
                       state (\s -> (chr i, s))             -- return
                     ) :: Int -> State Int Char) 10         >>= \i1 ->
                    inc 40                                  >>= \i2 ->
                    inc 8                                   >>= \i3 ->
                    return (i1, i2, i3))
{-
TWO VIEWS OF BIND:

    (State x) >>= f = State $ \s -> let (v,s') = x s in runState (f v) s'

  m >>= f  = StateT $ \s -> do
        ~(v, s') <- runStateT m s
        runStateT (f v) s'
-}
incerB2 :: Int -> ((Char,Char,Char), Int)
incerB2 = runState (((\x ->
                       -- definition of 'inc' expanded
                       state $ \s -> let (v,s') = (\s'' -> (s'', s'')) s        -- get
                                     in runState ((\i ->
                                                  state (\_ -> ((), i + x)) >>  -- put
                                                  state (\s'' -> (chr i, s''))) -- return
                                                  v) s'
                      ) :: Int -> State Int Char) 10        >>= \i1 ->
                    inc 40                                  >>= \i2 ->
                    -- last call to inc expanded
                    state $ \s -> let (v,s') = runState (inc 8) s
                                  in runState ((\i3 ->
                                                  return (i1, i2, i3))
                                               v) s')

rinc = U.tt "rinc"
               [ runState (inc   1) 45
               , runState (incB1 1) 45
               , runState (incB2 1) 45
               ,           incB3 1  45
               ,           incB4 1  45
               ]
               ('-',46)

ri = U.tt "ri" [ incer   45
               , incer1  45
               , incerB  45
               , incerB1 45
               , incerB2 45
               ]
               (('-','7','_'),103)

{-
------------------------------------------------------------------------------
14 The Reader monad

Computation: read values from shared env.
Binding: bound fun applied to bound value; both have access to shared env.
Use: Maintaining variable bindings, or other shared environment (e.g., configuration)
Zero/plus: None.
Example: Reader [(String,Value) a]

14.2 Motivation

Sometimes shared env needed (e.g., config).
Read vals from env and sometimes execute sub-computations in modified env
(with new or shadowing bindings)
Does not require full generality of State monad (often clearer and easier than using State).

14.3 Definition

Use multi-parameter type classes and funDeps.

-- fun from env to value
newtype Reader e a = Reader { runReader :: (e -> a) }

instance Monad (Reader e) where
    -- creates Reader that ignores given env, produces given value
    return a         = Reader $ \e -> a
    -- produces Reader that uses env to extract value of its left-hand side,
    -- then applies bound function to that value in same env
    (Reader r) >>= f = Reader $ \e -> runReader (f (r e)) e

class MonadReader e m | m -> e where
    -- retrieves env
    -- often used with a selector or lookup fun
    ask   :: m e
    -- executes computation in modified env
    local :: (e -> e) -> m a -> m a

instance MonadReader (Reader e) where
    ask       = Reader id
    local f c = Reader $ \e -> runReader c (f e)

asks :: (MonadReader e m) => (e -> a) -> m a
asks sel = ask >>= return . sel

14.4 Example

Instantiating templates that contain var substitutions and included templates.
Using Reader: maintain env of templates and var bindings.
When var substitution encountered, use 'asks' to lookup.
When new template included, use 'local' to resolve in modified env that contains additional var bindings.

see example16.hs

HC : example from monads step-by-step
-}
-- variable names
type Name   =  String
-- expressions
data Exp    =  Lit  Integer |  Var  Name |  Plus Exp  Exp |  Abs  Name Exp |  App  Exp  Exp
            deriving (Eq, Show)

-- values
data EValue =  IntVal Integer |  FunVal Env Name Exp
            deriving (Eq, Show)

-- names to values
type Env    =  Map.Map Name EValue

eval3             :: Exp -> Reader Env EValue
eval3 (Lit  i)     = return $ IntVal i
eval3 (Var  n)     = do env <- ask; return $ fromJust (Map.lookup n env)
eval3 (Plus e1 e2) = do (IntVal i1) <- eval3 e1
                        (IntVal i2) <- eval3 e2
                        return $ IntVal (i1 + i2)
eval3 (Abs  n  e)  = do env <- ask; return $ FunVal env n e
eval3 (App  e1 e2) = do (FunVal env' n body)  <- eval3 e1
                        val2  <- eval3 e2
                        local (const (Map.insert n val2 env')) (eval3 body)

exampleExp = Plus (Lit 12) (App (Abs "x" (Var "x")) (Plus (Lit 4) (Lit 2)))
t30 = U.t "t30"
     (runReader (eval3 exampleExp) Map.empty)
     (IntVal 18)

{-
------------------------------------------------------------------------------
The Writer monad

Computation: produce stream of data (in addition to computed values)
Binding: Value is (computation value, log value) pair.
         Replaces computation value with result of applying bound function to previous value.
         Appends current log data to existing.
Useful: Logging (computations that produce output "on the side")
Zero/plus: None.
Example: Writer [String a]

15.2 Motivation

Data generated during computation but not primary result.

Explicitly managing "side" data can clutter and/or cause bugs in code.
Writer in cleaner/safer.

15.3 Definition

Uses multi-parameter type classes and funDeps

Uses Monoid
- set of objects; identity element, closed associative binary operator
- e.g.: nats/0/+; nats/1/*;  list/[]/++

Haskell monoid: type, identity element (mempty), binary op (mappend)

WARM: using list as monoid for Writer: performance of mappend operation as output grows.
      Data structure with fast append operations better.

-- (value,log) where log type must be a monoid
newtype Writer w a = Writer { runWriter :: (a,w) }

instance (Monoid w) => Monad (Writer w) where
    return a             = Writer (a,mempty)
    (Writer (a,w)) >>= f = let (a',w') = runWriter $ f a in Writer (a',w `mappend` w')

class (Monoid w, Monad m) => MonadWriter w m | m -> w where
    pass   :: m (a,w -> w) -> m a
    listen :: m a -> m (a,w)
    tell   :: w -> m ()

instance (Monoid w) => MonadWriter (Writer w) where
    -- Converts Writer that produces value (a,f)/output w
    -- into     Writer that produces value a/outputf w
    -- cumbersome, so helper 'censor' normally used.
    pass   (Writer ((a,f),w)) = Writer ( a   ,f w)
    -- turns Writer that returns (value a, output w)
    -- into  Writer that produces value (a,w) and still produces output w.
    -- This enables computation to "listen" to log output generated by a Writer.
    listen (Writer ( a   ,w)) = Writer ((a,w),  w)
    -- adds one or more entries to log
    tell   s                  = Writer (   (),  s)

-- like listen except log part of value is modified by given function
listens :: (MonadWriter w m) => (w -> b) -> m a -> m (a,b)
listens f m = do (a,w) <- listen m; return (a,f w)

-- takes fun and Writer; produces Writer whose output is same but log entry modified by fun
censor :: (MonadWriter w m) => (w -> w) -> m a -> m a
censor f m = pass $ do a <- m; return (a,f)

15.4 Example

see zip: ../examples/example17.hs

another example: https://gist.github.com/davidallsopp/b7ecf8789efa584971c1
-}

logNumber :: Int -> Writer [String] Int
logNumber x = writer (x, ["Got number: " ++ show x])

-- do version separates logging from value
logNumberDo :: Int -> Writer [String] Int
logNumberDo x = do
    tell ["Got number: " ++ show x]
    return x

multWithLog :: Writer [String] Int
multWithLog = do
    a <- logNumber   3
    b <- logNumberDo 5
    tell ["multiplying " ++ show a ++ " and " ++ show b ]
    return (a*b)

exW = U.t "exW"
      (runWriter multWithLog)
      (15,["Got number: 3","Got number: 5","multiplying 3 and 5"])

{-
16 The Continuation monad

Computation: interrupted and resumed computations
Binding: creates new continuation that uses bound function as the continuation
Use: control structures, error handling, co-routines
Zero/plus: None.
Example: Cont r a

16.2 Motivation

Abuse of Continuation can make code impossible to understand/maintain.

Need to understand continuation-passing style (CPS).
Many algorithms that need continuations do not need them in LAZY Haskell.

Continuations represent the future of a computation
- as a function from intermediate result to final result.
Computations are sequences of nested continuations, terminated by final continuation (often id).
Manipulation of continuation function can cause complex manipulations of the future
- e.g., interrupt, abort, restart, interleave
Continuation monad adapts CPS to the structure of a monad.

16.3 Definition

-- Cont r a is a CPS computation
-- - produces intermediate result of type a within a CPS computation
-- - r is final result type of the whole computation
newtype Cont r a = Cont { runCont :: ((a -> r) -> r) }

instance Monad (Cont r) where
    -- creates continuation that passes value on
    -- i.e. return a = \k -> k a
    return a       = Cont $ \k -> k a
    -- adds bound function into the continuation chain
    -- i.e. c >>= f = \k -> c (\a -> f a k)
    (Cont c) >>= f = Cont $ \k -> c (\a -> runCont (f a) k)

class (Monad m) => MonadCont m where
    callCC :: ((a -> m b) -> m a) -> m a

instance MonadCont (Cont r) where
    -- Escape continuation : enables aborting current computation and returning value immediately.
    -- Similar to throwError/catchError n an Error monad.
    callCC f = Cont $ \k -> runCont (f (\a -> Cont $ \_ -> k a)) k

callCC calls fun with current continuation as arg.
Idiom: provide lambda-expression to name the continuation.
- calling named continuation in scope will escape from computation.

16.4 Example
-}

fun :: Int -> String
fun n = (`runCont` id) $
    callCC $ \exit1 -> do
        when (n < 10) (exit1 (show n ++ " exit1"))
        s2 <- callCC $ \exit2 -> do
            when (n <  20) (exit2 (show n ++ " exit2"))
            when (n == 50) (exit1 (show n ++ " exit1 from within exit2"))
            return $ show n ++ " return from exit1/exit2"
        return $ "return from exit1: " ++ s2

z = [(0,"0 exit1"),(9,"9 exit1")
    ,(10,"return from exit1: 10 exit2"),(19,"return from exit1: 19 exit2")
    ,(20,"return from exit1: 20 return from exit1/exit2"),(48,"return from exit1: 48 return from exit1/exit2")
    ,(50,"50 exit1 from within exit2")
    ,(51,"return from exit1: 51 return from exit1/exit2"),(746392736,"return from exit1: 746392736 return from exit1/exit2")
    ]

exCont = U.t "exCont"
         (map (fun . fst) z)
         (map        snd  z)

{-
------------------------------------------------------------------------------
Part III - Monad Transformers

17 Introduction

Part I  : monad concept
Part II : "standard" monads

Need to combine monads.

When one computation is a strict subset of the other, it is possible
to perform the monad computations separately, unless the
sub-computation is performed in a one-way monad.

When computations can't be performed in isolation, then need
monad that combines the features of the two+ monads into single computation.

Combine standard monads via monad transformers.

------------------------------------------------------------------------------
18 Combining monads the hard way

Exercise: combine monads without using transformers.

Why: develop insights into issues.

18.1 Nested Monads

Example of separate monads:

Code available in [[../examples/example19.hs|example19.hs]]

fun :: IO String
fun = do n <- (readLn::IO Int)         -- this is an IO monad block
         return $ (`runCont` id) $ do  -- this is a Cont monad block
           str <- callCC $ \exit1 -> do
             when (n < 10) (exit1 (show n))
             let ns = map digitToInt (show (n `div` 2))
             n' <- callCC $ \exit2 -> do
               when ((length ns) < 3) (exit2 (length ns))
               when ((length ns) < 5) (exit2 n)
               when ((length ns) < 7) $ do let ns' = map intToDigit (reverse ns)
                                           exit1 (dropWhile (=='0') ns')
               return $ sum ns
             return $ "(ns = " ++ (show ns) ++ ") " ++ (show n')
           return $ "Answer: " ++ str

18.2 Combined Monads

When nesting pattern (above) cannot be used, do computations within a
monad in which the values are themselves monadic values in another monad. E.g:
- Cont (IO String) : I/O in Continuation monad.
- State (Either Err a)

Example: require additional IO in middle of Continuation monad.
- user specify part of output value when input value satisfies predicate.

Cannot nest, because
- IO depends on part of Continuation compuation
- Continuation depends on the result of IO

Insead, make Continuation use values IO.
What used to be Int/String now IO Int/IO String.
Can't extract values from IO.

Code available in [[../examples/example20.hs|example20.hs]]
-}

toIO :: a -> IO a
toIO = return

funIO :: IO String
funIO = do n <- readLn::IO Int         -- this is an IO monad block
           convertIO n

convertIO :: Int -> IO String
convertIO n = (`runCont` id) $        -- this is a Cont monad block
    callCC $ \exit1 -> do    -- type IO String
        when (n < 10) (exit1 $ toIO (show n ++ " exit1"))
        s2 <- callCC $ \exit2 -> do   -- type IO String
            when (n  < 20) (exit2 (toIO (show n ++ " exit2")))
            when (n == 50) (exit1 $ do putStrLn "Enter a number:"
                                       x <- readLn::IO Int
                                       return (show n ++ " " ++ show x ++ " readline/exit1 from within exit2"))
            return (toIO $ show n ++ " return from exit1/exit2")
        return $ do s2' <- s2; return ("return from exit1: " ++ s2')

{-
to run in ghci:

    funIO

Works, but isn't pretty.

------------------------------------------------------------------------------
19 Monad transformers

Variants of standard monads that facilitate combining monads.
Type constructors parameterized over a monad type constructor: produce combined monadic types.

19.1 Transformer type constructors

'Reader r a' : environment of type r, values of type a.
Type constructor 'Reader r' is Monad class instance.
'runReader::(r->a)' : performs computation in Reader monad, returns result of type a.

Transformer version, 'ReaderT', adds a monad type constructor as an addition parameter.

'ReaderT r m a' is type of values of combined monad in which Reader is base monad
and m is inner monad.

'ReaderT r m' is monad class instance.
'runReaderT::(r -> m a)' performs computation in combined monad, returns result of type m a.

'ReaderT r IO' is combined Reader+IO monad.

Generate non-transformer version of a monad from transformer version
by applying it to the Identity monad:
  'ReaderT r Identity' same 'Reader r'

19.2 Lifting

Instead of creating additional do-blocks in a computation to manipulate values in inner monad,
use lifting operations to bring functions from inner monad into the combined monad.

Each monad transformer provides lift function to lift a monadic
computation into a combined monad.

Many transformers also provide a liftIO.

Code available in [[../examples/example21.hs|example21.hs]]
-}

funIOCT :: IO String
funIOCT = (`runContT` return) $ do
    n   <- liftIO (readLn::IO Int)
    callCC $ \exit1 -> do
        when (n < 10) (exit1 (show n ++ " exit1"))
        s2 <- callCC $ \exit2 -> do
            when (n  < 20) (exit2  (show n ++ " exit2"))
            when (n == 50) $ do liftIO $ putStrLn "Enter a number:"
                                x <- liftIO (readLn::IO Int)
                                exit1 (show n ++ " " ++ show x ++ " readline/exit1 from within exit2")
            return $ show n ++ " return from exit1/exit2"
        return $ "return from exit1: " ++ s2

{-
Compare 'funIOCT' with 'convertIO'

------------------------------------------------------------------------------
20 Standard monad transformers

Haskell has classes which represent monad transformers and transformer versions of standard monads.

20.1 The MonadTrans and MonadIO classes

The (Control.Monad.Trans) MonadTrans class provides 'lift'.
- lifts monadic computation in inner monad into combined monad.

class MonadTrans t where
    lift :: (Monad m) => m a -> t m a

MonadIO defines liftIO:

class (Monad m) => MonadIO m where
    liftIO :: IO a -> m a

20.2 Transformer versions of standard monads

It is not the case the all monad transformers apply the same transformation.

E.g.:

ContT turns (a->r)->r into (a->m r)->m r.
StateT turns s->(a,s) into s->m (a,s).

No magic formula to create transformer version of a monad — depends on
what makes sense in its context.

Standard   Transformer   Original Type   Combined Type
Error      ErrorT        Either e a      m (Either e a)
State      StateT        s -> (a,s)      s -> m (a,s)
Reader     ReaderT       r -> a          r -> m a
Writer     WriterT       (a,w)           m (a,w)
Cont       ContT         (a -> r) -> r   (a -> m r) -> m r

Order important when combining monads.

StateT s (Error e) different than ErrorT e (State s).
- 1st : s -> Error e (a,s) : computation can either return a new state or generate an error.
- 2nd : s -> (Error e a,s) : computation always returns a new state; value can be error or normal value.

Anatomy of a monad transformer

21 Anatomy of a monad transformer

Detailed look at StateT.

21.1 Combined monad definition

newtype State  s   a = State  { runState  :: (s ->   (a,s)) }

newtype StateT s m a = StateT { runStateT :: (s -> m (a,s)) }

State s    : instance of Monad and MonadState s classes.
StateT s m : ditto
- if m is an instance of MonadPlus, StateT s m should also be a member of MonadPlus.

instance (Monad m) => Monad (StateT s m) where
    return a          = StateT $ \s -> return (a,s)
    (StateT x) >>= f  = StateT $ \s -> do -- get new value, state
                                          (v,s')      <- x s
                                          -- apply bound function to get new state transformation fn
                                          (StateT x') <- return $ f v
                                          -- apply state transformation fn to the new state
                                          x' s'


Compare to definition for State s.
- 'return'  makes use of 'return' inner monad
- binding uses 'do' to perform computation in inner monad.

Combined monads that use StateT transformer must be instaces of MonadState:

instance (Monad m) => MonadState s (StateT s m) where
    get   = StateT $ \s -> return (s,s)
    put s = StateT $ \_ -> return ((),s)

And

instance (MonadPlus m) => MonadPlus (StateT s m) where
    mzero = StateT $ \s -> mzero
    (StateT x1) `mplus` (StateT x2) = StateT $ \s -> (x1 s) `mplus` (x2 s)

21.2 Defining the lifting function

TODO: LEFT OFF RIGHT HERE
-}

------------------------------------------------------------------------------

testing =
    TT.runTestTT $ TT.TestList $
        mom1 ++ dad1 ++ mgf1 ++ mpgf1 ++ listEx ++ mgf2 ++ dmgf2 ++ mgf3 ++ dmgf3 ++ prnt1 ++ prnt2 ++
        seqExM ++ seqExL ++ seqExF ++ mapMExM ++ fm ++ mff ++ mff ++ zipWithMHC ++ gn ++ ac1 ++ ac2 ++ ac3 ++
        apEx1 ++ apEx2 ++ apEx3 ++ ms1 ++ ms2 ++ ms3 ++ gyt1 ++ gyt2 ++
        mail1 ++ mail2 ++ mail3 ++ mail4 ++ p1 ++ p2 ++ p3 ++ sr1 ++ sr2 ++ sr3 ++
        ranT ++ rinc ++ ri ++ t30 ++ exW ++ exCont

test :: IO ()
test = do
    testing
{-
    let dolly = breedSheep
    seq_ExM
    mapM_ExM
    _ <- zipWithM_HC
    rg
-}
    return ()


-- End of file.

