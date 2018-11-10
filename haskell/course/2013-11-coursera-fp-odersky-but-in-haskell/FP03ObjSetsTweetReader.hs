{-
Created       : 2013 Oct 01 (Tue) 21:00:47 by carr.
Last Modified : 2014 Mar 05 (Wed) 13:14:28 by Harold Carr.
-}

{-# LANGUAGE OverloadedStrings #-}

module FP03ObjSetsTweetReader where

import           Control.Applicative
import           Control.Monad
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as C8
import           FP03ObjSetsTweetSet

data Tweets = Tweets
    { tweets :: [Tweet]
    } deriving Show

instance FromJSON Tweets where
    parseJSON (Object t) = Tweets <$>
                           t .: "tweets"
    parseJSON _ = mzero

instance FromJSON Tweet where
    parseJSON (Object t) = Tweet <$>
                           t .: "user" <*>
                           t .: "text" <*>
                           t .: "retweets"
    parseJSON _ = mzero

parseTweets :: Monad m => String -> m Tweets
parseTweets x =
    let toParse = C8.pack x
      in case (eitherDecode' toParse :: Either String Tweets) of
        Right r -> return r
        Left e -> error (show e)

-- TODO : this blows up runghc - but is seen by hlint (regardless of where I put it in file)
-- {-# ANN allTweets "HLint: ignore Eta reduce" #-}
allTweets :: [Tweets] -> TweetSet
allTweets {- tweets -} = foldr outerStep Empty {- tweets -}
  where outerStep (Tweets tl) acc = foldr (flip incl) acc tl

-- End of file.
