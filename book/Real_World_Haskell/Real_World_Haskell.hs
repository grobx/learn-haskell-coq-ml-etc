-- Real World Haskell

{-
Created       : 2011 Dec 31 (Sat) 19:56:38 by carr.
Last Modified : 2013 Jul 31 (Wed) 21:50:07 by carr.

http://blog.tty.nl/category/haskell/real-world-haskell/
http://haskell.elkstein.org/2009/04/solutions-to-chapter-4-p-97.html
-}

-- HC: 2013-07-30: what is this for?
-- import RecursiveContents

import Data.Char (digitToInt, isDigit, isSpace)
import Data.Either
import Data.List
import Data.Ord
import Data.Maybe (fromJust)
import Debug.Trace
import System.FilePath

debug = flip trace

{- ======================================================================== -}
-- 1 Getting Started

{-
:?
:set prompt "ghci> "
-- interactively load a module:
:module + Data.Ratio
:info (^)
:i    (^)
:type (^)
:t    (^)
-- tell us more about types:
:set +t
:unset +t
-- ghci store value of last evaluated expression in:  it

WC.hs
quux.txt
runghc WC < quux.txt

:info truncate pi
:type truncate pi

:info succ
:type succ 6

:info sin
:type sin (pi / 2)

:info floor
:type floor 3.7

:show bindings
let x = 3
:show bindings

-- Exercises p 16

-- 3
WC.hs
-}

{- ======================================================================== -}
-- 2 Types and Functions

{-
()
(1)
(1,2)

:type readFile

:load <filename>
:l    <filename>

:cd <dir>

myDrop.hs
:l myDrop.hs
myDrop 2 "foobar"                             ==  "obar"
myDrop 7 "foobar"                             ==  ""
myDrop 7 []                                   ==  []
myDrop (-2) "foobar"                          ==  "foobar"

parametric polymorphic functions : have type variables in their signature,
indicating (some) of args can be of any type

parametric : "normal" function has parameters that we can be bound to values,
a Haskell type can have parameters that can be bound to types.

Def: parameterized or polymorphic type: if a type contains type parameters.

OO languages usually have subtype polymorphism (via subclassing).
Haskell is not oo. It does not provide subtype polymorphism.

Coercion polymorphism: value of one type implicitly converted into
value of another type (e.g., auto conversion between ints and floats).
Haskell deliberately avoids this.

Any nonpathological function of type (a,b) -> a must do exactly what fst does.
See "Theorems for free" by Philip Wadler
http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.38.9875
-}

-- Exercises p 39/79

-- 2 and 3

lastButOne  ::  [a] -> a
lastButOne       [] = error "empty list"
lastButOne      [_] = error "list of one element"
lastButOne    [x,_] = x
lastButOne   (_:xs) = lastButOne xs

{-
lastButOne []                                 --  *** Exception: empty list
lastButOne [1]                                --  *** Exception: list of one element
lastButOne [1,2,3,4]                          ==  3
-}

{- ======================================================================== -}
-- 3 Defining Types, Streamlining Functions

-- BookInfo is a type  constructor -- (i.e., the type’s name) used only in a type declaration
-- Book     is a value constructor --                        used      in code
-- Int, String, ... are components of the type (a field/slot where we keep a value)
-- fields are anonymous/positional - referenced by location, not name

--                           ID  TITLE  AUTHORS
data BookInfo     = Book     Int String [String]
    deriving (Show)

-- (data BookInfo = BookInfo ... also OK where type and value constructor have same name)

-- distinct from (Int, String, [String])
-- and:

data MagazineInfo = Magazine Int String [String]
    deriving (Show)

myInfo = Book 9780135072455 "Algebra of Programming" ["Richard Bird", "Oege de Moor"]

{-
:i myInfo
:t myInfo
-}

-- type synonyms
type CustomerID = Int
type ReviewBody = String
data BookReview = BookReview BookInfo CustomerID ReviewBody

type BookRecord = (BookInfo, BookReview)

-- algebraic data types

data MyBool = MyFalse | MyTrue

type CardHolder  = String
type CardNumber  = String
type Address     = [String]
data BillingInfo = CreditCard CardNumber CardHolder Address
                 | CashOnDelivery
                 | Invoice CustomerID
                 deriving (Show)
{-
:t CreditCard
-}

myCreditCard = CreditCard "2901650221064486" "Thomas Gradgrind" ["Dickens", "England"]


{-
:t myCreditCard
Invoice -- gets error because you cannot print functions in Haskell
-}

type Vector = (Double, Double)
data Shape  = Circle Vector Double
            | Poly [Vector]

{-
-- pattern matching
- If type has > 1 value constructor, distinguish which value constructor was used to create the value.
- If value constructor has components, then extract those values.
-}

bookID      (Book id _     _      ) = id
bookTitle   (Book _  title _      ) = title
bookAuthors (Book _  _     authors) = authors

{-
GHC : -fwarn-incomplete- patterns
      print warning if patterns do not match all of a type’s value constructors.
-}

-- record syntax (to generate boilerplate accessors):

data Customer = Customer {
      customerID      :: CustomerID
    , customerName    :: String
    , customerAddress :: Address
} deriving (Show)

-- and to enable "keyword" any-order args to constructors


-- parameterized types

-- "a" is a type variable
data MyMaybe a = MyJust a
               | MyNothing


-- recursive types

data MList a = MCons a (MList a)
             | MNil
               deriving (Show)

-- Exercises p 60/100

-- 1

-- from haskell list to "my" list
fromHList (      x:xs) = MCons x (fromHList xs)
fromHList           [] = MNil

fromMList (MCons x xs) = x:fromMList xs
fromMList         MNil = []

-- fromHList [1,2,3]
-- fromMList (MCons 1 (MCons 2 (MCons 3 MNil)))
-- (fromMList $ fromHList [1,2,3,4,5])        ==  [1,2,3,4,5]

data Tree a = Node a (Tree a) (Tree a)
            | Empty
              deriving (Eq, Show)

{-
TODO: Why the Int viz Integer difference?:
ghci> t1
Node 1 Empty Empty
it :: Tree Int
ghci> t1'
Node 1 Empty Empty
it :: Tree Integer
-}
t0  = Empty
t1  = Node 1 Empty                Empty
t3  = Node 2 t1                   (Node 3 Empty Empty)
t4  = Node 2 t1                   (Node 3 Empty (Node 4 Empty Empty))

t0' = Empty
t1' = Node 1 Empty                Empty
t3' = Node 2 (Node 1 Empty Empty) (Node 3 Empty Empty)
t4' = Node 2 (Node 1 Empty Empty) (Node 3 Empty (Node 4 Empty Empty))

-- Exercises p 60/100

-- 2

data Tree' a = Tree' a (Maybe (Tree' a)) (Maybe (Tree' a)) deriving (Show)
t0'' = Nothing -- not a Tree' - WRONG
t1'' = Tree' 1 Nothing     Nothing
t3'' = Tree' 2 (Just t1'') (Just (Tree' 3 Nothing Nothing))
t4'' = Tree' 2 (Just t1'') (Just (Tree' 3 Nothing (Just (Tree' 4 Nothing Nothing))))


lastButOne' :: [a] -> Maybe a
lastButOne'     []  = Nothing
lastButOne'    [_]  = Nothing
lastButOne'  [x,_]  = Just x
lastButOne' (_:xs)  = lastButOne' xs

{-
lastButOne' []                                ==  Nothing
lastButOne' [1]                               ==  Nothing
lastButOne' [1,2,3,4]                         ==  Just 3
-}

-- local variables

lend amount balance  = let reserve    = 100
                           newBalance = balance - amount
                       in if balance < reserve
                          then Nothing
                          else Just newBalance

lend2 amount balance = if amount < reserve * 0.5
                       then Just newBalance
                       else Nothing
    where reserve    = 100
          newBalance = balance - amount

{-
GHC: -fwarn-name-shadowing
     warn when we shadow a name
-}

-- local functions

pluralise :: String -> [Int] -> [String]
pluralise word counts = map plural counts
    where plural 0 = "no " ++ word ++ "s"
          plural 1 = "one " ++ word
          plural n = show n ++ " " ++ word ++ "s"

-- case

myFromMaybe defaultValue wrapped =
    case wrapped of
        Nothing    -> defaultValue
        Just value -> value

-- Irrefutable patterns : a pattern that always succeeds
-- e.g., plain variable names and _

-- conditional evaluation with guards

nodesAreSame (Node a _ _) (Node b _ _) | a == b = Just a
nodesAreSame            _            _          = Nothing

lend3 amount balance | amount <= 0            = Nothing
                     | amount > reserve * 0.5 = Nothing
                     | otherwise              = Just newBalance
    where reserve    = 100
          newBalance = balance - amount

dropper n xs = if n <= 0 || null xs
               then xs
               else dropper (n - 1) (tail xs)

dropper' n     xs | n <= 0 = xs
dropper' _     []          = []
dropper' n (_:xs)          = dropper (n - 1) xs

-- exercises - p 69/

-- 1 and 2
myLength :: Num a => [t] -> a
myLength     [] = 0
myLength (x:xs) = 1 + (myLength xs)

testMyLength l = myLength l == length l
-- testMyLength [4,5,6,7,8,9]                 == True

-- 3
mean l = sum l / fromIntegral (length l)

-- 4
palindrome x = x ++ (reverse x)

-- 5
-- TODO extend this to handle lists of odd length
isPalindrome x | not (even (length x)) = False
               | otherwise =
                     let n = truncate $ fromIntegral (length x) / 2 `debug` show (truncate $ fromIntegral (length x) / 2)
                         t = (take n x)                             `debug` show (take n x)
                         d = (drop n x)                             `debug` show (drop n x)
                     in t == reverse d
-- isPalindrome [1,2,3,3,2,1]                 ==  True
-- isPalindrome [1,2,3,2,2,1]                 ==  False

-- 6
six = sortBy (\x y -> if length x < length y
                      then LT
                      else if length x == length y
                           then EQ
                           else GT)
             [[1,2], [1,2,3,4], [1], []]
-- six                                        ==  [[],[1],[1,2],[1,2,3,4]]

-- 7 and 8

intersperse' :: a -> [[a]] -> [a]
intersperse' s xs = concat (i s xs)
    where i _    []   = []
          i s (x:[] ) = [x]
          i s (x:xs') = x : [s] : (i s xs')
{-
intersperse' ',' []                           ==  ""
intersperse' ',' ["foo"]                      ==  "foo"
intersperse' ',' ["foo","bar","baz","quux"]   ==  "foo,bar,baz,quux"
intersperse'  0  [[1]  ,[2]  ,[3]  ,[4]   ]   ==  [1,0,2,0,3,0,4]
-}

-- 9 max height of tree
-- http://blog.moertel.com/articles/2012/01/26/the-inner-beauty-of-tree-traversals
-- TODO: UNDERSTAND

flatten traversal = reverse . traversal (:) []

-- "fold" f through the values in a tree
traverse :: (t2 -> (t -> t) -> (t -> t) -> t -> t)
            -> (t1 -> t2)
            -> t
            -> Tree t1
            -> t
traverse step f z tree = go tree z
  where
    go Empty        z = z
    go (Node v l r) z = step (f v) (go l) (go r) z

preorder  :: (t -> b -> b) -> b -> Tree t -> b
preorder   = traverse $ \n l r -> r . l . n

inorder   :: (t -> b -> b) -> b -> Tree t -> b
inorder    = traverse $ \n l r -> r . n . l

postorder :: (t -> b -> b) -> b -> Tree t -> b
postorder  = traverse $ \n l r -> n . r . l

test1p = flatten preorder  t3  -- [2,1,3]
test1i = flatten inorder   t3  -- [1,2,3]
test1o = flatten postorder t3  -- [1,3,2]

-- exercise answer
ninep3 = preorder  max minBound t3

allMax  = map (\f -> map (f (max) minBound) [t0,t1,t3,t4]) [(preorder),(inorder),(postorder)]
allCons = map (\f -> map (f (:)   [])       [t0,t1,t3,t4]) [(preorder),(inorder),(postorder)]

-- just traverse left or right

leftorder  = traverse $ \n l r -> l . n
rightorder = traverse $ \n l r -> r . n

treemin = leftorder  min maxBound
treemax = rightorder max minBound

test2l = treemin t3 :: Int
-- test2l                                     == 1
test2r = treemax t3 :: Int
-- test2r                                     == 3

-- 10

data Point = Point Int Int     deriving (Eq, Show)
data Direction = DLeft     Point Point Point
               | DStraight Point Point Point
               | DRight    Point Point Point
                 deriving (Eq, Show)

-- 11

-- TODO: need trigonometry to do this...
turn p1@(Point x1 y1) p2@(Point x2 y2) p3@(Point x3 y3) =
    DLeft p1 p2 p3

turn' :: Point -> Point -> Point -> Direction
turn' p1 p2 p3 =
    DLeft p1 p2 p3

-- 12

turns :: [Point] -> [Direction]
turns l@(p1:p2:p3:ps) = turn p1 p2 p3 : turns (tail l)
turns               _ = []
-- let ts = turns [Point 1 1, Point 2 2, Point 3 1, Point 5 6, Point (-1) 3, Point 4 0]
-- length ts

-- 13 TODO p 70/110

{- ======================================================================== -}
-- 4 Functional Programming p 71/111

{-
InteractWith.hs
:l  InteractWith.hs

ghc --make InteractWith

cat hello-in.txt

InteractWith hello-in.txt /tmp/hello-out.txt

-- line splitting
:t lines
lines :: String -> [String]
lines "line 1\nline 2"                        ==  ["line 1","line 2"]
lines "foo\n\nbar\n"                          ==  ["foo","","bar"]

lines, readFile and writeFile use "text mode" that converts (in and out) \n <-> \r\n   .
But problem when reading a file written on a different system.

lines "a\r\nb"                                ==  ["a\r","b"]

Instead, provide something like Python's "universal newline" support.

SplitLines.hs

-- break : takes function to say where to break list
:t break
break :: (a -> Bool) -> [a] -> ([a], [a])
break odd [2,4,5,6,8]                         ==  ([2,4],[5,6,8])
:module +Data.Char
break isUpper "isUpper"                       ==  ("is","Upper")

:l  SplitLines.hs
splitLines "foo"                              ==  ["foo"]
break isLineTerminator "foo"                  ==  ("foo","")
splitLines "foo\r\nbar"                       ==  ["foo","bar"]
break isLineTerminator "foo\r\nbar"           ==  ("foo","\r\nbar")
splitLines "bar"                              ==  ["bar"]
"foo" : ["bar"]                               ==  ["foo","bar"]

unlines ["1","2","3","4"]                     ==  "1\n2\n3\n4\n"

cat FixLines.hs
ghc --make FixLines

file     gpl-3.0.txt
unix2dos gpl-3.0.txt
file     gpl-3.0.txt

FixLines gpl-3.0.txt /tmp/JUNK
file /tmp/JUNK
-}


-- data can be defined INFIX (besides function defs)
data a `Pair` b = a `Pair` b deriving (Show)
fooPair = Pair 1 2.0
barPair = True `Pair` "quux"

{-
-- working with lists - p 77/117

-- Prelude reexports some of Data.List contents
:module +Data.List

length []                                     ==  0
length [1,2,3]                                ==  3

null []                                       ==  True
head [1]                                      ==  1
tail [1]                                      ==  []
last [1,2]                                    ==  2
init [1,2,3,4]                                ==  [1,2,3]

-- partial function: has return values for subset of valid inputs (e.g., head, tail, last, init, ...)
-- total   function: has return values for       all valid inputs

-- append
"foo" ++ "bar"                                ==  "foobar"
[1,2] ++ [3,4]                                ==  [1,2,3,4]

-- removes ONE level of nesting
concat [[1,2,3], [], [3,4]]                   ==  [1,2,3,3,4]
concat [[[1,2],[3]], [[4],[5],[6]]]           ==  [[1,2],[3],[4],[5],[6]]
concat (concat [[[1,2],[3]], [[4],[5],[6]]])  ==  [1,2,3,4,5,6]

reverse [1,2]                                 ==  [2,1]
([2,1] == [2.1])                              ==  False

and [True, True, True]
or  [True, True, True]

:type all
all :: (a -> Bool) -> [a] -> Bool
all odd [1,3,5]                               ==  True
all odd [3,1,4,1,5,9,2,6,5]                   ==  False
all odd []                                    ==  True
:type any
any :: (a -> Bool) -> [a] -> Bool
any even [3,1,4,1,5,9,2,6,5]                  ==  True
any even []                                   ==  False
all even []                                   ==  True

:type take
take :: Int -> [a] -> [a]
take 3 "foobar"                               ==  "foo"
take 2 [1]                                    ==  [1]
:type drop
drop :: Int -> [a] -> [a]
drop 3 "xyzzy"                                ==  "zy"
drop 1 []                                     ==  []

:type splitAt
splitAt :: Int -> [a] -> ([a], [a])
splitAt 3 "foobar"                            ==  ("foo","bar")

:type takeWhile
takeWhile :: (a -> Bool) -> [a] -> [a]
takeWhile odd [1,3,5,6,8,9,11]                ==  [1,3,5]
:type dropWhile
dropWhile :: (a -> Bool) -> [a] -> [a]
dropWhile even [2,4,6,7,9,10,12]              ==  [7,9,10,12]
:type span
span :: (a -> Bool) -> [a] -> ([a], [a])
-- consumes while predicate succeeds
span even [2,4,6,7,9,10,11]                   ==  ([2,4,6],[7,9,10,11])
:type break
break :: (a -> Bool) -> [a] -> ([a], [a])
-- consumes while predicate fails
break even [1,3,5,6,8,9,10]                   ==  ([1,3,5],[6,8,9,10])

:type elem
elem :: Eq a => a -> [a] -> Bool
(2 `elem` [5,3,2,1,1])                        ==  True
(2 `notElem` [5,3,2,1,1])                     ==  False

:type filter
filter :: (a -> Bool) -> [a] -> [a]
filter odd [2,4,1,3,6,8,5,7]                  ==  [1,3,5,7]

"foo" `isPrefixOf` "foobar"                   ==  True
"needle" `isInfixOf` "haystack full of needle thingies"  ==  True
"end" `isSuffixOf` "the end"                  ==  True

:type zip
zip :: [a] -> [b] -> [(a, b)]
zip [12,72,93] "zippity"                      ==  [(12,'z'),(72,'i'),(93,'p')]
:type zipWith
zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]
zipWith (+) [1,2,3] [4,5,6]                   ==  [5,7,9]
:type zip7
zip7
  :: [a]
     -> [b]
     -> [c]
     -> [d]
     -> [e]
     -> [f]
     -> [g]
     -> [(a, b, c, d, e, f, g)]
:type zipWith7
zipWith7
  :: (a -> b -> c -> d -> e -> f -> g -> h)
     -> [a] -> [b] -> [c] -> [d] -> [e] -> [f] -> [g] -> [h]

unlines (lines "foo\nbar")                    == "foo\nbar\n"

words "the \r quick \t brown\n\n\nfox"        ==  ["the","quick","brown","fox"]
unwords ["jumps", "over", "the", "lazy", "dog"] ==  "jumps over the lazy dog"
-}

-- exercises - p 84/124

-- 1

safeHead :: [a] -> Maybe a
safeHead     []  = Nothing
safeHead (x:xs)  = Just x

safeTail :: [a] -> Maybe [a]
safeTail     []  = Nothing
safeTail (x:xs)  = Just xs

safeLast :: [a] -> Maybe a
safeLast     []  = Nothing
safeLast    [x]  = Just x
safeLast (x:xs)  = safeLast xs

safeInit :: [a] -> Maybe [a]
safeInit     []  = Nothing
safeInit    [x]  = Just []
safeInit (x:xs)  = Just (x : (fromJust (safeInit xs)))

-- 2
-- similar to words but takes predicate and works on any type

-- Note:
-- - both versions split on true (rather than false of exercise)
-- - both versions retain the split character (rather than discard it)

-- Version written January 2012
splitWith :: (a -> Bool) -> [a] -> [[a]]
splitWith f x = splitWith' f x []
    where splitWith' _     [] acc             = [reverse acc]
          splitWith' f (x:xs) acc | f x       =  reverse acc : splitWith' f xs [x]
                                  | otherwise =                splitWith' f xs (x : acc)
{-
splitWith odd [1,2,3,4,5,6,7]                 ==  [[],[1,2],[3,4],[5,6],[7]]
splitWith odd [2,4,5,6,8,9]                   ==  [[2,4],[5,6,8],[9]]
splitWith odd [2,4,5,6,8,9,10,12]             ==  [[2,4],[5,6,8],[9,10,12]]
-}

-- Version written July 2013
swt _ [] = []
swt f xs =
    let (sp,cont) = sw f xs -- `debug` show (sw f xs)
    in
        case sp of
            [] -> [cont]
            _  -> case cont of
                      []     -> [sp]
                      x':xs' -> sp : (x' : head step) : (tail step) where step = swt f xs'

-- swt odd [2,4,5,6,8,9,10,12]                ==  [[2,4],[5,6,8],[9,10,12]]

sw _     [] = ([], [])
sw f (x:xs) | f x       = ([], x:xs) -- use @
            | otherwise = (x:sp, cont) where (sp,cont) = sw f xs

--      sw odd [2,4,5,6,8,9,10,12]
-- fst (sw odd [2,4,5,6,8,9,10,12])
-- snd (sw odd [2,4,5,6,8,9,10,12])

--           sw odd [6,8,9,10,12]
--     (fst (sw odd [6,8,9,10,12]))
-- 5 : (fst (sw odd [6,8,9,10,12]))
--     (snd (sw odd [6,8,9,10,12]))

--           sw odd [9,10,12]

--           sw odd [10,12]

-- The beginning of a third version July 2013
sw' _ (x:[]) = ([], x, [])
sw' f (x:xs) | f x       = ([], x, xs) -- use @
             | otherwise = (x:b, sp, cont) where (b,sp,cont) = sw' f xs

-- Now look at: http://hackage.haskell.org/packages/archive/split/0.1.1/doc/html/src/Data-List-Split-Internals.html

-- 3 print first word of each line

firstWord x = map (head . words) (lines x)
-- firstWord "first line\nsecond line\nthird line"  ==  ["first","second","third"]

-- 4 transpose text (e.g., "hello\nworld\n" to "hw\neo\nlr\nll\nod\n")

transposeText x = unlines $ map (\(x,y) -> x:y:[]) (zip (lins!!0) (lins!!1)) where lins = lines x
-- transposeText "hello\nworld\n"             ==  "hw\neo\nlr\nll\nod\n"

-- lines "hello\nworld\n"                     ==  ["hello","world"]
-- (lines "hello\nworld\n")!!1                ==  "world"
-- zip ((lines "hello\nworld\n")!!0) ((lines "hello\nworld\n")!!1)  ==  [('h','w'),('e','o'),('l','r'),('l','l'),('o','d')]

transposeText' x = unlines $ concat $ transposeText'' (lines x) 0
    where transposeText'' lins i =
              if (not $ null lins) && (not $ null $ tail lins)
              then tt (lins!!0) (lins!!1) : transposeText'' (tail (tail lins)) (i + 2)
              else []
          tt l1 l2 = map (\(x,y) -> x:y:[]) (zip l1 l2)
-- transposeText' "hello\nworld\n"            ==  "hw\neo\nlr\nll\nod\n"

{-
-- loops

explicit recursion
- base (terminating)    case : empty list
- inductive (recursive) case : ...

mapping

selecting pieces of input via filter

computing one answer over a collection : foldl/foldr
-}

-- p 92/132

-- FOLDL (LEFT)

-- "zero" is initial value and accumulator
myFoldl :: (a -> b -> a) -> a -> [b]   -> a
myFoldl    step             zero (x:xs) = myFoldl step (step zero x) xs
myFoldl    _                zero []     = zero
-- myFoldl (*)     1 [5,  4,  3,  2]
-- myFoldl (*)    (1* 5) [4,  3,  2]
-- myFoldl (*)   ((1* 5)* 4) [3,  2]
-- myFoldl (*)  (((1* 5)* 4)* 3) [2]
-- myFoldl (*) ((((1* 5)* 4)* 3)* 2) []
--             ((((1* 5)* 4)* 3)* 2)

foldlSum xs = myFoldl step 0 xs
    where step acc x = acc + x
-- foldlSum [5,4,3,2,1]                       ==  15

niceSum :: [Integer] -> Integer
niceSum = foldl (+) 0

filter' :: (a -> Bool) -> [a] -> [a]
filter' p []                 = []
filter' p (x:xs) | p x       = x : filter' p xs
                 | otherwise =     filter' p xs

-- FOLDR (RIGHT)

myFilter p xs = foldr step [] xs
    where step x ys | p x       = x : ys
                    | otherwise =     ys
-- myFilter odd [1, 2, 3, 4]                  ==  [1,3]
--              (1  : (3 : []))

myMap :: (a -> b) -> [a] -> [b]
myMap f xs = foldr step [] xs
    where step x ys = f x : ys

myFoldl' :: (a -> b -> a) -> a -> [b] -> a
myFoldl' f z xs = foldr step id xs z
    where step x g a = g (f a x)

identity :: [a] -> [a]
identity xs = foldr (:) [] xs

-- ++
append :: [a] -> [a] -> [a]
append xs ys = foldr (:) ys xs

{-
-- Left Folds, Laziness, and Space Leaks

NEVER USE FOLDL IN PRACTICE.

Because of nonstrict evaluation.

             foldl (+)    0  (1 :  2 :  3 : [])
          == foldl (+)   (0 + 1)  (2 :  3 : [])
          == foldl (+)  ((0 + 1) + 2)  (3 : [])
          == foldl (+) (((0 + 1) + 2) + 3)  []
          ==           (((0 + 1) + 2) + 3)

Final expr not be evaluated to 6 until value needed.
Before evaluated, stored as thunk.
Thunk more expensive to store than single number.
The more complex the thunked expression, the more space it needs.
More computationally expensive than evaluating it immediately.
Paying both in space and in time.
Uses internal stack to evaluate thunk.
Space leak.
Easy to avoid.  Use non-lazy fold'

foldl (+) 0 [1..10000000]                     ==  50000005000000
:module +Data.List
foldl' (+) 0 [1..10000000]                    ==  50000005000000
-}

-- Exercises - p 97/137

-- 1, 2 and 3 write asInt from p 85/125 (repeated below) using fold? and error

loop :: Int -> String -> Int
loop acc       [] = acc
loop acc ('-':xs) = - (loop acc xs)
loop acc   (x:xs) = let acc' = acc * 10 + digitToInt x
                    in loop acc' xs
asInt :: String -> Int
asInt xs = loop 0 xs
{-
asInt "27"                                    ==   27
asInt "-27"                                   ==  -27
asInt "2-7"                                   ==  -27  -- WRONG
asInt "27-"                                   ==  -27  -- WRONG
asInt "2.7"                                   --  *** Exception: Char.digitToInt: not a digit '.'
-}

asInt' xs = if not (null xs) && head xs == '-'
            then - ai (tail xs)
            else   ai       xs
    where ai xs = foldl (\acc x -> acc * 10 + dig x) 0 xs
          dig x = if isDigit x then digitToInt x else error ("wrong: " ++ (show x))

-- the big number becomes:                564616105916946374
-- map (asInt') ["33", "", "-", "-3", "314159265358979323846", "101", "-31337", "1798"]  ==  [33,0,0,-3,564616105916946374,101,-31337,1798]
-- asInt' "potato"                            --  *** Exception: wrong: 'p'
-- asInt' "2.7"                               --  *** Exception: wrong: '.'
-- asInt' "2-7"                               --  *** Exception: wrong: '-'

-- 4 Use Data.Either with above
-- TODO : there must be a better way
aaInt' xs = if not (null xs) && head xs == '-'
            then m (ai (tail xs))
            else    ai       xs
    where m (Left  a)   = Left    a
          m (Right b)   = Right (-b)
          ai xs         = foldl (\acc x -> d acc x) (Right 0) xs
          d (Left  a) _ = Left a
          d (Right b) x = dig b x
          dig acc x     = if isDigit x
                          then Right (acc * 10 + (digitToInt x))
                          else Left ("wrong: " ++ (show x))

-- map (aaInt') ["33", "", "-", "-3", "314159265358979323846", "101", "-31337", "1798", "potato", "2.7"]  ==  [Right 33,Right 0,Right 0,Right (-3),Right 564616105916946374,Right 101,Right (-31337),Right 1798,Left "wrong: 'p'",Left "wrong: '.'"]

-- 5 and 6 concat using foldr

concat' = foldr (++) []
-- concat' [[1,2,3],[4,5,6]]                  ==  [1,2,3,4,5,6]

-- 7 takeWhile recursive

tw _     []             = []
tw f (x:xs) | f x       = x:(tw f xs)
            | otherwise = []
-- map (tw odd) [[1,3,4], [], [2,3]]          ==  [[1,3],[],[]]

-- 7 takeWhile foldr

tw' f = foldr (\x acc -> if (f x) then x:acc else []) []

-- map (tw' odd) [[1,3,4], [], [2,3]]         ==  [[1,3],[],[]]
-- tw'(\x -> 6*x < 100) [1..20]               ==  [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]

-- 8 and 9 Data.List (groupBy) : use ghci to figure out what it does then write your own with a fold
{-
:module Data.List
:t groupBy
groupBy :: (a -> a -> Bool) -> [a] -> [[a]]
:i groupBy
groupBy :: (a -> a -> Bool) -> [a] -> [[a]]
  	-- Defined in `Data.List'
TODO: read:
http://www.cs.nott.ac.uk/~gmh/fold.pdf
-}
-- NOTE: critical to implement a groupBy clone (saw this after implementing some of below)
-- groupBy (>) [4,2,3,1,3,5,2,3,2,1]          ==  [[4,2,3,1,3],[5,2,3,2,1]]

-- NOTE: this one really kicked my ass
-- Took forever to get something past the type checker
-- And then it doesn't work correctly on all args (e.g., run testGb)
-- NOTE: after understanding more, I see my gbr is a useful finer-grained function in its own right
--       its only problem being it doesn't follow the definition of groupBy
gbr   :: (a -> a -> Bool) -> [a] -> [[a]]
gbr _ []       = []
gbr f xs       = foldr (gb') [[last xs]] (init xs)
    where gb' y ((y':ys):yss) = if f y y' then ((y:y':ys):yss) else [y]:((y':ys):yss)

-- only difference from gbr is order of operands to F in where clause
gbr'  :: (a -> a -> Bool) -> [a] -> [[a]]
gbr' _ []      = []
gbr' f xs      = foldr (gb') [[last xs]] (init xs)
    where gb' y ((y':ys):yss) = if f y' y then ((y:y':ys):yss) else [y]:((y':ys):yss)

gbl   :: (a -> a -> Bool) -> [a] -> [[a]]
gbl _ []       = []
gbl f (x:xs)   = foldl (gb') [[x]] xs
    where gb' ((y':ys):yss) y = if f y y' then (((y':ys)++[y]):yss) else ((y':ys):yss++[[y]])

-- only difference from gbl is order of operands to F in where clause
gbl'  :: (a -> a -> Bool) -> [a] -> [[a]]
gbl' _ []      = []
gbl' f (x:xs)  = foldl (gb') [[x]] xs
    where gb' ((y':ys):yss) y = if f y' y then (((y':ys)++[y]):yss) else [y]:((y':ys):yss)

-- only difference from gbl' is reverse
-- NOTE: this one behaves like groupBy (courtesy REVERSE)
gbl'' :: (a -> a -> Bool) -> [a] -> [[a]]
gbl'' _ []     = []
gbl'' f (x:xs) = reverse $ foldl (gb') [[x]] xs
    where gb' ((y':ys):yss) y = if f y' y then (((y':ys)++[y]):yss) else [y]:((y':ys):yss)

-- TODO try to write using a fold and span (see official groupBy definition)

testGb gb = map (\(op,name) -> map (\xs -> let mygb = gb (op) xs
                                               hsgb = groupBy (op) xs
                                           in if mygb == hsgb then ("", [], [[]], [[]]) else (name, xs, mygb,hsgb))
                                   [[4,2,3,1,3,5,2,3,2,1], [], [1,2,3,4,5,6,7,8,9], [1,2,2,4,5,5,7,2,5], [1,2,2,2,3,4,4,2]])
                [((>)                         , ">")
                ,((==)                        , "==")
                ,((/=)                        , "/=")
                ,((\x y -> x `mod` y == 0)    , "(\\x y -> x `mod` y == 0)")
                ,((\x y -> (x*y `mod` 3) == 0), "(\\x y -> (x*y `mod` 3) == 0)")
                ]

printTestGb :: Show a => [[a]] -> IO [()]
printTestGb     [] = return [()]
printTestGb (x:xs) = do
    putStrLn $ show x
    printTestGb xs

{-
testGb groupBy
testGb gbr
testGb gbr'
testGb gbl
testGb gbl'
testGb gbl''
mapM (printTestGb) $ map (testGb)                                                    [(groupBy), (gbl''), (gbr), (gbr'), (gbl), (gbl')]
mapM (\(r,n) -> do putStrLn "------"; putStrLn n; printTestGb r) $ zip (map (testGb) [(groupBy), (gbl''), (gbr), (gbr'), (gbl), (gbl')]) ["groupBy", "gbl''", "gbr", "gbr'", "gbl", "gbl'"]
-}


-- Definition from Data.List: http://www.haskell.org/ghc/docs/latest/html/libraries/base/src/Data-List.html#groupBy

groupBy'                 :: (a -> a -> Bool) -> [a] -> [[a]]
groupBy' _  []           =  []
groupBy' eq (x:xs)       =  (x:ys) : groupBy' eq zs
                            where (ys,zs) = span (eq x) xs

-- groupBy  (\x y -> (x*y `mod` 3) == 0) [1,2,3,4,5,6,7,8,9]  ==  [[1],[2,3],[4],[5,6],[7],[8,9]]
-- groupBy' (\x y -> (x*y `mod` 3) == 0) [1,2,3,4,5,6,7,8,9]  ==  [[1],[2,3],[4],[5,6],[7],[8,9]]



-- 10 Write using folds if possible

-- any using foldr
anyr f = foldr (\x acc -> acc || f x) False
{-
anyr works on finite lists
anyr (>100) [1,2,1,4,101,79]                  ==  any (>100) [1,2,1,4,101,79]

but not on infinite lists, because it needs to find the end (right) to even start
anyr (>100) [1..]                             --  DO NOT TRY, HANGS MAC
-}
-- any using foldl
anyl f = foldl (\acc x -> acc || f x) False
{-
works on finite lists, but expense since it has to traverse entire list (even after finding True) building thunks
anyl (>2) [1,2,3]                             ==  any (>2) [1,2,3]

but not on infinite lists, because it needs to find end of list to terminate
anyl (>100) [1..]                             -- DO NOT TRY, HANGS MAC
-}

-- cycle
-- cannot be implemented as a fold since producing an infinite list

-- words
-- the REAL definition:
words' :: String -> [String]
words' s =  case dropWhile isSpace s of
                "" -> []
                s' -> w : words s''
                    where (w, s'') = break isSpace s'
-- TODO: not sure if this can be a fold

-- unlines

unlinesr = foldr (\x acc -> if acc == "" then x++"\n" else x++"\n"++acc) ""
unlinesl = foldl (\acc x -> if acc == "" then x++"\n" else acc++x++"\n") ""

{-
unlinesl ["1","2","3","4"]                    ==  unlines ["1","2","3","4"]
unlinesr ["1","2","3","4"]                    ==  unlines ["1","2","3","4"]
unlinesl (lines "foo\nbar")                   ==  unlines (lines "foo\nbar")
unlinesr (lines "foo\nbar")                   ==  unlines (lines "foo\nbar")
-}

{- ======================================================================== -}
-- 5 JSON p 111/151

{-
John Hughes : "The Design of a Pretty-Printing library"
http://citeseer.ist.psu.edu/hughes95design.html
Improved by Simon Peyton Jones
Included in Haskell

This chapter based on simpler Philip Wadler's "A prettier printer"
http://citeseerx.ist.psu.edu/viewdoc/summary?doi =10.1.1.19.635
Extended by Daan Leijen.
Install:
cabal install wl-pprint.

ghci

SimpleJSON.hs
PutJSON.hs

-- produces
--   *.hi : interface file for use when compiling modules that use it
--   *.o  : object file
ghc -c SimpleJSON.hs
ghc -c PutJSON.hs

:l SimpleJSON
getString (JString "hello")                   ==  Just "hello"
getString (JNumber 3)                         ==  Nothing
:l PutJSON
let json = JObject [("foo", JNumber 1), ("bar", JBool False), ("boo", JArray [JString "baz", JNull])]
print json
renderJValue json
putJValue json

-- intercalate is used by PutJSON
:module Data.List
:i intercalate
intercalate :: [a] -> [[a]] -> [a] 	-- Defined in Data.List
-- NO: see type: intercalate  0  [ 1,  2,  3,  4,  5]
intercalate [0] [[1],[2],[3],[4],[5]]         ==  [1,0,2,0,3,0,4,0,5]
intercalate "," ["a","b","c","d"]             ==  "a,b,c,d"

:i intersperse
intersperse :: a -> [a] -> [a] 	-- Defined in Data.List
intersperse  0  [ 1,  2,  3,  4,  5]          ==  [1,0,2,0,3,0,4,0,5]
intersperse [0] [[1],[2],[3],[4],[5]]         ==  [[1],[0],[2],[0],[3],[0],[4],[0],[5]]
intersperse ',' "abcd"                        ==  "a,b,c,d"

-- following file cats PrettyJSON and Prettify together so I can get inside
PrettyJSON.hs
Prettify.hs
PrettyJSONPrettify.hs
:l PrettyJSONPrettify
text "foo" <> text "bar"                      ==  Concat (Text "foo") (Text "bar")
text "foo" <> empty                           ==  Text "foo"
empty <> text "bar"                           ==  Text "foo"
let json = JObject [("foo", JNumber 1), ("bar", JBool False), ("boo", JArray [JString "baz", JNull])]
:t json
json :: JValue
json
let jvalue = renderJValue json
:type jvalue
jvalue :: Doc
jvalue
compact jvalue
putStrLn (compact jvalue)
empty </> char 'a'                            ==  Concat (Union (Char ' ') Line) (Char 'a')
2 `fits` " a"                                 ==  True
2 `fits` "          a"                        ==  False
putStrLn (pretty 10 jvalue)
putStrLn (pretty 20 jvalue)
putStrLn (pretty 30 jvalue)

-- Exercises p 130/170

-- fill TODO
fill :: Int -> Doc -> Doc

-- add support for nesting TODO



-- creating a package using Cabal p 131/171

ghc-pkg        list
ghc-pkg --user list

PrettyJSON.cabal
PrettyJSONSetup.hs

runghc PrettyJSONSetup configure
runghc PrettyJSONSetup build

ll -R dist

-- TODO INSTALL
-- DOES NOT WORK
cabal install prettyjson --dry-run

-}

{- ======================================================================== -}
-- 6 Using Typeclasses
-- TODO - do again - especially from p 149/189

{-

Typeclasses enable defining generic interfaces that provide a common
feature set over a variety of types.

Typeclasses define a set of functions that have different
implementations depending on the type of data they are given.

"class" below has NOTHING to do with OO "class"

-}

-- provides defaults for each function
-- instance only needs to implement one
class BasicEq a where
    isEqual    :: a -> a -> Bool
    isEqual       x    y = not (isNotEqual x y)
    isNotEqual :: a -> a -> Bool
    isNotEqual    x    y = not (isEqual    x y)

-- types are made instances of a typeclass by implementing
-- the functions necessary for that typeclass
instance BasicEq Bool where
    isEqual True  True  = True
    isEqual False False = True
    isEqual _     _     = False

{-
-- Haskell's definition
class Eq a where
    (==), (/=) :: a -> a -> Bool
    -- Minimal complete definition:
    -- (==) or (/=)
    x /= y = not (x == y)
    x == y = not (x /= y)

-- Built-in Typeclasses

-- to convert values to Strings
Show

define a Show instance for your own types
instance Show Color where
    show Red   = "Red"
    show Green = "Green"
    show Blue  = "Blue"

-- to convert String to a instance of a type
Read

:type (read "5")
:type (read "5")::Integer
(read "5")::Integer
:type (read "5")::Double
(read "5")::Double

-- define an instance of Read (a parser) for your types
-- Must return the result AND the part of the input that was not
-- parsed so that the system can integrate the parsing of different types
-- together.
-- NOTE: most people use Parsec instead of Read instances.

instance Read Color where
    readsPrec _ value = tryParse [("Red", Red), ("Green", Green), ("Blue", Blue)]
        where tryParse [] = [] -- fail
              tryParse ((attempt, result):xs) =
                  if (take (length attempt) value) == attempt
                  -- match, return result and remaining input
                  then [(result, drop (length attempt) value)]
                  else tryParse xs
-}

-- http://www.haskell.org/pipermail/haskell-cafe/2010-July/080920.html

data JValue = JString String
            | JNumber Double
            | JBool   Bool
            | JNull
            | JObject [(String, JValue)]
            | JArray  [JValue]
              deriving (Eq, Ord, Show)

type JSONError = String

class JSON a where
    toJValue   :: a       -> JValue
    fromJValue :: JValue  -> Either JSONError a

instance JSON JValue where
    toJValue               = id
    fromJValue             = Right

instance JSON Bool where
    toJValue               = JBool
    fromJValue   (JBool b) = Right b
    fromJValue           _ = Left "not a JSON boolean"

instance JSON Int where
    toJValue               = JNumber . realToFrac
    fromJValue             = doubleToJValue round

instance JSON Integer where
    toJValue               = JNumber . realToFrac
    fromJValue             = doubleToJValue round

instance JSON Double where
    toJValue               = JNumber
    fromJValue             = doubleToJValue id

doubleToJValue :: (Double -> a) -> JValue -> Either JSONError a
doubleToJValue f (JNumber v) = Right (f v)
doubleToJValue _ _           = Left "not a JSON number"

{-
toJValue $ JString "foo"
toJValue $ JBool True
toJValue JNull
toJValue $ JNumber 3.4
[fromJValue (JBool True), Right JNull]
[fromJValue (JBool True), Right True]
[fromJValue (JNumber 2.1), Right 2.1]
[fromJValue (JNumber 2.1), Right (JNumber 2.1)]
[fromJValue "foo", Left "bar"]
fromJValue (JBool False) :: Either JSONError Bool
fromJValue (JBool False) :: Either JSONError JValue
-}

{- ======================================================================== -}
-- 7 I/O
-- TODO

{- ======================================================================== -}
-- 8 File Processing, Regular Expressions, Filename Matching
-- TODO

{- ======================================================================== -}
-- 9 I/O Case Study : unix "find"

{-
ghci

-- 213/254
cat RecursiveContents.hs
:l RecursiveContents
getRecursiveContents ".."

-- 215/255
cat SimpleFinder.hs
:l SimpleFinder
simpleFind id "."

:m +System.FilePath
:t takeExtension
simpleFind (\p -> takeExtension p == ".hs") "."

-- 217/257
:m +System.Directory
:t doesFileExist
doesFileExist "."
doesDirectoryExist "."
:i getPermissions
:i Permissions
getPermissions "."
getModificationTime "."

-- 218/258
cat BetterPredicate.hs
:l BetterPredicate
betterFind myTest "."
:t betterFind (sizeP `equalP` 1024)
betterFind myTest2 "."
betterFind myTest3 "."
betterFind myTest4 "."

-- controlling traversal p 226/266
cat ControlledVisit.hs
:l ControlledVisit

traverse id "."
let filterP = foldl (\acc x -> let test = maybe False executable . infoPerms in if test x then x:acc else acc) []
traverse filterP "."

-- another way 230/270
cat FoldDir.hs
:l FoldDir
foldTree atMostThreePictures [] "."
foldTree countDirectories    0  "."

-- exercises 232/272
-- TODO

-- exercises 234/274
-- TODO
-}


{- ======================================================================== -}
-- 10 Code Case Studay: Parsing a Binary Data Format 235/275

{-
cat PNM.hs
:l PNM

cat Parse.hs
:l Parse.hs
:t parse (identity 1) undefined
parse (identity 1) undefined
parse (identity "foo") undefined
let before = ParseState (L8.pack "foo") 0
let after = modifyOffset before 3
before
after

cat TreeMap.hs
:l TreeMap.hs
let tree = Node (Leaf "foo") (Node (Leaf "x") (Leaf "quux"))
treeLengths tree
treeMap length tree
treeMap (odd . length) tree
 map length ["foo", "quux"]
fmap length ["foo", "quux"]
 map length (Node (Leaf "Livingstone") (Leaf "I presume"))
fmap length (Node (Leaf "Livingstone") (Leaf "I presume"))

:l Parse
parse parseByte L.empty
parse (id <$> parseByte) L.empty
let input = L8.pack "foo"
L.head input
parse parseByte input
parse (id <$> parseByte) input
parse ((chr . fromIntegral) <$> parseByte) input
parse (chr <$> fromIntegral <$> parseByte) input

-- RIGHT HERE
-}

{- ======================================================================== -}
-- 21 Using Databases

{-
cabal --dry-run install HDBC
cabal           install HDBC
cabal --dry-run install HDBC-postgresql
cabal           install HDBC-postgresql
:module Database.HDBC Database.HDBC.PostgreSQL
:t connectPostgreSQL
conn <- connectPostgreSQL "host=/tmp dbname=hcdb"
:t conn
quickQuery' conn "SELECT * from books" []
quickQuery' conn "SELECT * from authors" []
r <- quickQuery' conn "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_schema='public'" []
fromSql (head (head r)) :: String
fromSql $ head $ head r :: String
map (\hr -> fromSql $ head hr :: String) r


disconnect conn
-}
