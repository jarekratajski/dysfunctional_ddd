{-# LANGUAGE DeriveGeneric #-}

module SnakeModel where

import           GHC.Generics

import           Data.Aeson   (FromJSON, ToJSON, ToJSONKey (..))
{- import Data.Map (delete, empty, insert, lookup)-}
import           Data.Map     ()
-- import qualified Data.Text    as T (Text, pack)

data SnakeCell = SnakeCell
   { cellX :: Int
   , cellY :: Int
   } deriving (Show, Eq, Generic, Ord)

data SnakeState
   = Alive { direction :: SnakeDirection
           , cells     :: [SnakeCell]
           , maxLength :: Int }
   | Dead
   | Init
   deriving (Eq, Show, Generic)

data SnakeData = SnakeData
   { name  :: String
   , state :: SnakeState
   } deriving (Eq, Show, Generic)

data SnakeDirection
   = SnakeUp
   | SnakeRight
   | SnakeDown
   | SnakeLeft
   deriving (Eq, Show, Generic)

data SnakeEvent
   = StepMade
   | DirectionChanged { newDirection :: SnakeDirection }
   | Killed
   | Born { bornName :: String
          , bornCell :: SnakeCell }
   | HasEaten { eatenCell :: SnakeCell }
   deriving (Eq, Show, Generic)

data SnakeCommand
   = MakeStep
   | SetDirection { wantedDirection :: SnakeDirection }
   | Die
   | Eat { cellToEat :: SnakeCell }
   | Begin { initName :: String
           , initCell :: SnakeCell }
   deriving (Show)

type UUID = String

data SnakeInMemRepository =
   Map UUID
       SnakeState

initialSnake :: SnakeData
initialSnake = SnakeData {name = "baby snake", state = Init}

-- JSON
instance ToJSON SnakeCell

instance ToJSON SnakeState

instance ToJSON SnakeDirection

instance ToJSON SnakeData

instance ToJSON SnakeEvent

instance ToJSONKey SnakeCell
{-where
   toJSONKey = toJSONKeyText myKeyToText
     where
       myKeyToText = T.pack . cellToText -- or showt from text-show
-}
instance FromJSON SnakeDirection

cellToText :: SnakeCell -> String
cellToText c = "cell_" ++ show (cellX c) ++ "_" ++ show (cellY c)
