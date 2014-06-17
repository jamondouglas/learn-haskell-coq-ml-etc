{-
Created       : 2014 Jun 15 (Sun) 17:51:15 by Harold Carr.
Last Modified : 2014 Jun 16 (Mon) 21:34:14 by Harold Carr.
-}

module HW07_HC_JoinList where

import           HW07_HC_Scrabble
import           HW07_Sized

import           Data.Monoid      (Monoid (..), Product (..), mempty, (<>))

import qualified Test.HUnit       as T
import qualified Test.HUnit.Util  as U

------------------------------------------------------------------------------
-- This version used for rest of file.

-- defer append operations
-- use-case: for text editing : breaks document into pieces that can be processed individually (instead of traversing entire document)

-- 'm' is metadata (i.e., monoidal annotations)
-- annotation at root will be equal to combination of of annotation on single nodes
-- according to use-specific "combining" operation
data JoinList m a = Empty
                  | Single m a
                  | Append m (JoinList m a) (JoinList m a)
                  deriving (Eq, Show)

-- used in testing later
toList :: JoinList m a -> [a]
toList Empty            = []
toList (Single _ a)     = [a]
toList (Append _ l1 l2) = toList l1 ++ toList l2

ex :: JoinList (Product Int) Char
ex = Append (Product 210)
            (Append (Product 30)
                    (Single (Product 5) 'y')
                    (Append (Product 6)
                            (Single (Product 2) 'e')
                            (Single (Product 3) 'a')))
            (Single (Product 7) 'h')

------------------------------------------------------------------------------
-- Exercise 1

-- gets the annotation
tag :: Monoid m => JoinList m a -> m
tag Empty          = mempty
tag (Single m _)   = m
tag (Append m _ _) = m

-- append yields new JoinList whose annotation is derived from the two args
(+++) :: Monoid m => JoinList m a -> JoinList m a -> JoinList m a
(+++) x y = Append (tag x <> tag y) x y

ex1 :: T.Test
ex1 = T.TestList
    [
      U.teq "e0"                                                 (Empty +++ (Single (Product (3::Int)) "right"))
                                              (Append (Product 3) Empty     (Single (Product  3)       "right"))
    , U.teq "e1"                           ((Single (Product 2) "left") +++ (Single (Product (3::Int)) "right"))
                        (Append (Product 6) (Single (Product 2) "left")     (Single (Product  3)       "right"))
    ]

------------------------------------------------------------------------------
-- Exercise 2

-- fast indexing of a JoinList
-- cache size (num data elements) of each subtree
-- use-case: determine if given index in left or right branch

-- Helper
-- TODO - is there a way to make this local to indexJ where it can be used in the guard too?
gst :: (Sized b, Monoid b) => JoinList b a -> Int
gst = getSize . size . tag

-- 1.

indexJ :: (Sized b, Monoid b) => Int -> JoinList b a -> Maybe a
-- indexJ _  Empty                       = Nothing -- not necessary - covered by guard
-- indexJ  0 s@(Single _ _)              = Just s -- TODO
indexJ i0 jl            | i0 >= gst jl        = Nothing
                        | otherwise           = ij i0 jl
  where
    ij _ (Single _ a)                  = Just a
    ij i (Append _ l r) | i < gst l    = ij i           l
                        | otherwise    = ij (i - gst l) r

-- 2.

-- The instructions do not state whether the returned JoinList should be balanced.  This returns unbalanced.
-- Note: added Eq for testing.
dropJ :: (Eq a, Sized b, Monoid b) => Int -> JoinList b a -> JoinList b a
dropJ 0 s@(Single _ _)                 = s
dropJ i0 jl             | i0 >= gst jl = Empty
                        | otherwise    = dj i0 jl
  where
    dj _ s@(Single _ _)                = s
    dj i (Append _ l r) | i < gst l    = dj i l +++ r
                        | otherwise    = dj (i - gst l) r

-- 3.

takeJ :: (Eq a, Sized b, Monoid b) => Int -> JoinList b a -> JoinList b a
takeJ  0 _                             = Empty
takeJ i0 jl             | i0 >= gst jl = jl
                        | otherwise    = tj (i0 - 1) jl
  where
    tj _ s@(Single _ _)                = s
    tj i (Append _ l r) | i < gst l    = tj i l
                        | otherwise    = l +++ tj (i - gst l) r

--------------------------------------------------
-- test

-- create a balanced tree
yeah :: JoinList Size Char
yeah = ((Single (Size 1) 'y') +++ (Single (Size 1) 'e')) +++
       ((Single (Size 1) 'a') +++ (Single (Size 1) 'h'))
{-
Append (Size 4)
       (Append (Size 2)
               (Single (Size 1) 'y')  -- 0
               (Single (Size 1) 'e')) -- 1
       (Append (Size 2)
               (Single (Size 1) 'a')  -- 2
               (Single (Size 1) 'h')) -- 3
-}

abcl :: JoinList Size Char
abcl = Append (Size 9)
              (Append (Size 5)
                      (Append (Size 2)
                              (Single (Size 1) 'a')
                              (Single (Size 1) 'b'))
                      (Append (Size 3)
                              (Append (Size 2)
                                      (Single (Size 1) 'c')
                                      (Single (Size 1) 'd'))
                              (Single (Size 1) 'e')))
              (Append (Size 4)
                      (Append (Size 2)
                              (Single (Size 1) 'f')
                              (Single (Size 1) 'g'))
                      (Append (Size 2)
                              (Single (Size 1) 'h')
                              (Single (Size 1) 'i')))

abcr :: JoinList Size Char
abcr = Append (Size 9)
              (Append (Size 4)
                      (Append (Size 2)
                              (Single (Size 1) 'a')
                              (Single (Size 1) 'b'))
                      (Append (Size 3)
                              (Single (Size 1) 'c')
                              (Single (Size 1) 'd')))
              (Append (Size 5)
                      (Append (Size 2)
                              (Single (Size 1) 'e')
                              (Single (Size 1) 'f'))
                      (Append (Size 3)
                              (Single (Size 1) 'g')
                              (Append (Size 2)
                                      (Single (Size 1) 'h')
                                      (Single (Size 1) 'i'))))


(!!?) :: [a] -> Int -> Maybe a
[]     !!? _         = Nothing
_      !!? i | i < 0 = Nothing
(x:_)  !!? 0         = Just x
(_:xs) !!? i         = xs !!? (i-1)

same :: (Eq a, Monoid m, Sized m) => JoinList m a -> [Either (Int, Maybe a, Maybe a) Bool]
same jl = [ go i0 | i0 <- [ 0 .. gst jl - 1] ]
  where
    go i | ij == tl  = Right True
         | otherwise = Left (i, ij, tl)
      where
        ij = indexJ i jl
        tl = toList jl !!? i

dropper :: (Eq a, Sized b, Monoid b) => Int -> JoinList b a -> Bool
dropper n jl = toList (dropJ n jl) == drop n (toList jl)

ex2 :: T.Test
ex2 = T.TestList
    [
      U.teq "e210" (same yeah)                                 (replicate 4 (Right True))
    , U.teq "e211" (indexJ 4 yeah)                             Nothing
    , U.teq "e212" (toList yeah !!? 4)                         Nothing
    , U.teq "e213" (same abcl)                                 (replicate 9 (Right True))
    , U.teq "e213" (indexJ 9 abcl)                             Nothing
    , U.teq "e214" (same abcr)                                 (replicate 9 (Right True))
    , U.teq "e215" (indexJ 9 abcr)                             Nothing

    , U.teq "e220" (dropJ 9 (dropJ 2 (Single (Size 1) 'i')))   Empty
    , U.teq "e221" (dropJ 0 (Single (Size 1) 'i'))             (Single (Size 1) 'i')
    , U.teq "e222" (dropJ 8 abcl)                              (Single (Size 1) 'i')
    , U.teq "e223" (dropJ 7 abcr)                              (Append (Size 2) (Single (Size 1) 'h') (Single (Size 1) 'i'))
    , U.teq "e224" (dropper 2 abcl)                            True

    , U.teq "e230" (takeJ 9 (dropJ 2 (Single (Size 1) 'i')))   Empty
    , U.teq "e231" (takeJ 1          (Single (Size 1) 'i'))    (Single (Size 1) 'i')
    , U.teq "e232" (takeJ 2          (Single (Size 1) 'i'))    (Single (Size 1) 'i')
    , U.teq "e233" (takeJ 0          abcl)                     Empty
    , U.teq "e234" (takeJ 1          abcl)                     (Single (Size 1) 'a')
    , U.teq "e235" (takeJ 2          abcl)                     (Append (Size 2) (Single (Size 1) 'a') (Single (Size 1) 'b'))
    ]

------------------------------------------------------------------------------
-- Exercise 3

scoreLine :: String -> JoinList Score String
scoreLine s = (Single (scoreString s) s)

ex3 :: T.Test
ex3 = T.TestList
    [
      U.teq "e31" (score 'c')                                  (Score 3)
    , U.teq "e32" (score 'z')                                  (Score 10)
    , U.teq "e33" (scoreString "Harold")                       (Score 4+1+1+1+1+2)
    , U.teq "e34" (scoreLine "yay " +++ scoreLine "haskell!")  (Append (Score 23) (Single (Score 9) "yay ") (Single (Score 14) "haskell!"))
    ]

------------------------------------------------------------------------------
-- Exercise 4

ex4 :: T.Test
ex4 = T.TestList
    [
    ]

------------------------------------------------------------------------------

-- TODO: remove this when final
t :: IO T.Counts
t = hw07

hw07 :: IO T.Counts
hw07 = do
    T.runTestTT ex1
    T.runTestTT ex2
    T.runTestTT ex3
    T.runTestTT ex4

-- End of file.