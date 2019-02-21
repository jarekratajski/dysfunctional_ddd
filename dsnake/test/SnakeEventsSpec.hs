module SnakeEventsSpec (spec) where

import SnakeModel as Snake
import SnakeAggregate as SnakeLogic
import Data.Aeson(encode)
import qualified Data.ByteString.Lazy.Char8 as L(unpack)

import Test.Hspec
import Test.Hspec.QuickCheck


initialCell= SnakeCell { cellX = 4, cellY = 5}
cellUp= SnakeCell { cellX = 4, cellY = 4}

aliveSnakeUp =  Snake.SnakeData {name = "wij", state = Snake.Alive{ direction = Snake.SnakeUp, cells = [initialCell], maxLength = 3 }}
aliveSnakeLeft =  Snake.SnakeData {name = "wij", state = Snake.Alive{ direction = Snake.SnakeLeft, cells = [initialCell], maxLength = 3 }}



commandDown = Snake.SetDirection  { wantedDirection = Snake.SnakeDown}

expectedSnakeMovedUp = Snake.SnakeData {name = "wij", state = Snake.Alive{ direction = Snake.SnakeUp, cells = [cellUp, initialCell], maxLength = 3}}

spec :: Spec
spec = do
    describe "change direction" $ do
        prop "opposite" $
            SnakeLogic.executeCommand  aliveSnakeUp commandDown  == []
        prop "orthogonal" $
                        SnakeLogic.executeCommand aliveSnakeLeft  commandDown  == [Snake.DirectionChanged { newDirection = Snake.SnakeDown }]
    describe "events" $ do
         prop ("onestep " ++ (show moveSnakeOneStep) ++ "==" ++  (show expectedSnakeMovedUp)) $
            moveSnakeOneStep == expectedSnakeMovedUp
         prop ("json encode"  ) $ \x y ->
            (L.unpack $ encode $ aCell x y  ) == aString x y
      where
            moveSnakeOneStep = SnakeLogic.applyEvent aliveSnakeUp StepMade
            aString x y = "{\"cellY\":"++ (show y) ++",\"cellX\":"++ (show x ) ++"}"
            aliveSnake x y = Snake.SnakeData {name = "wij", state = Snake.Alive{ direction = Snake.SnakeUp, cells = [aCell x y], maxLength = 3}}
            aCell x y  = SnakeCell { cellX = x, cellY = y}

