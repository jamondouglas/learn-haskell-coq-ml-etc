{-# LANGUAGE OverloadedStrings #-}

{-
Created       : 2014 Mar 03 (Mon) 20:39:50 by Harold Carr.
Last Modified : 2014 Mar 10 (Mon) 18:17:21 by Harold Carr.
-}

module BitlyClientCommon where

import           Data.List    (intercalate)
import qualified Network.HTTP as H (urlEncode)

bitlyApiV3 :: String
bitlyApiV3  = "https://api-ssl.bitly.com/v3/"

-- the version in Network.HTTP does not do the right thing
urlEncodeVars :: [(String,String)] -> String
urlEncodeVars = intercalate "&" . uev
  where
    uev ((n,v):t) = (H.urlEncode n ++ "=" ++ H.urlEncode v) : uev t
    uev        [] = []

-- End of file.
