{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}


module Game.SnakePlane where

import           Data.IORef
import qualified Data.Map     as Map (Map, empty, insert, lookup, size, delete, filterWithKey)
import           Data.Maybe
import           GHC.Generics
import qualified SnakeAggregate   as Logic (applyEventX, newCells, newSnake, removedCells)
-- this is projection
import qualified SnakeModel   as Snake
import qualified SnakeRepo    as Repo
import           Data.Aeson      (ToJSON)


data CellType
   = PlayerCell { uid :: Repo.SnakeId }
   | Fruit
   deriving (Eq, Show, Generic)

data PlaneCell = PlaneCell
   { snakeCell :: Snake.SnakeCell
   , cellType  :: CellType
   } deriving (Eq, Show, Generic)

type CellsMap = Map.Map Snake.SnakeCell PlaneCell

data CellChange = CellChange { created::[PlaneCell], destroyed::[PlaneCell]} deriving (Show, Generic)

data Changes = Changes { lastNr::Int, history :: Map.Map Int CellChange } deriving (Show, Generic)

data PlaneState = PlaneState
   { allSnakes :: Repo.SnakesMap
   , allCells  :: CellsMap
   , changes :: Changes
   } deriving (Show, Generic)

type Plane = IORef PlaneState

initialPlane :: PlaneState
initialPlane = PlaneState {allSnakes = Repo.emptySnakesMap, allCells = Map.empty, changes = Changes { lastNr = 0, history = Map.empty }}

data ProjectionResult = ProjectionResult
   { plane :: PlaneState
   }


applyEvent :: PlaneState -> Repo.SnakeQualifiedEvent -> (PlaneState, [Repo.SnakeQualifiedCmd])
applyEvent aPlane qEvent = (newPlane, newCommands)
  where
    anUid = Repo.snakeId qEvent
    anEvent = Repo.event qEvent
    oldSnakeMaybe = Map.lookup anUid repo
    oldSnake = fromMaybe Snake.initialSnake oldSnakeMaybe
    repo = allSnakes aPlane
    applyResult = Logic.applyEventX oldSnake anEvent
    newSnakeData = Logic.newSnake applyResult
    newSnakesRepo = Map.insert anUid newSnakeData repo
    createdCells = Logic.newCells applyResult
    destroyedCells = Logic.removedCells applyResult
    oldCells = allCells aPlane
    shouldSnakeDie = shouldDieL aPlane createdCells
    newCells = addSnakeCells oldCells createdCells anUid
    newCellsAlive = removeSnakeCells newCells destroyedCells anUid
    newCommands = if shouldSnakeDie  then [Repo.SnakeQualifiedCmd anUid Snake.Die] else []
    createdPlaneCells = makePlaneCells createdCells anUid
    destroyedPlaneCells = makePlaneCells destroyedCells anUid
    newChanges = updateChanges (changes aPlane) CellChange { created = createdPlaneCells, destroyed = destroyedPlaneCells}
    newPlane = PlaneState {allSnakes = newSnakesRepo, allCells = newCellsAlive, changes = newChanges}


getHistory::PlaneState->Int->Changes
getHistory PlaneState{changes = allChanges}  nr =
   Changes { lastNr = lastNr allChanges, history = Map.filterWithKey ( \k _ -> (k >= nr)) aHistory }
   where
      aHistory =  history allChanges

makePlaneCells::[Snake.SnakeCell]->String->[PlaneCell]
makePlaneCells cells anUid = (\c -> PlaneCell {snakeCell = c, cellType = PlayerCell {uid = anUid} } )<$> cells

updateChanges::Changes->CellChange->Changes
updateChanges Changes{..}  chg = Changes { lastNr =nextNr, history = cleanedMap }
   where
      nextNr = lastNr + 1
      updatedMap = Map.insert nextNr chg history
      cleanedMap  = Map.delete (lastNr - 50) updatedMap


shouldDie::PlaneState->Snake.SnakeCell->Bool
shouldDie aPlane cell = maybe False (\_ -> True) cellAtSamePlace
      where
            existingCells = allCells aPlane
            cellAtSamePlace = Map.lookup cell existingCells

shouldDieL::PlaneState->[Snake.SnakeCell]->Bool
shouldDieL aPlane cells = foldl  (\res p -> res || shouldDie aPlane p ) False cells



addSnakeCells :: CellsMap -> [Snake.SnakeCell] -> Repo.SnakeId -> CellsMap
addSnakeCells aMap cells anUid = foldl updateFunc aMap cells
  where
    updateFunc = (\m cell -> Map.insert cell PlaneCell {snakeCell = cell, cellType = PlayerCell {uid = anUid}} m)

removeSnakeCells :: CellsMap -> [Snake.SnakeCell] -> Repo.SnakeId -> CellsMap
removeSnakeCells aMap cells _  = foldl (\m c -> Map.delete c m) aMap cells



getBestPlaceForNextSnake::PlaneState->Snake.SnakeCell
getBestPlaceForNextSnake aPlane = findFree (allCells aPlane) firstX firstY
         where
               noSnakes = Map.size $ allSnakes aPlane
               firstX = 10 + 2*noSnakes
               firstY = 12 + 3*noSnakes

findFree::CellsMap->Int->Int->Snake.SnakeCell
findFree cellsMap x y = maybe (aCell) (\_ -> findFree cellsMap (x+2) (y+3))  occupiedCell
         where
               aCell = Snake.SnakeCell {Snake.cellX = x, Snake.cellY = y }
               occupiedCell = Map.lookup aCell cellsMap


instance ToJSON CellType
instance ToJSON PlaneCell
instance ToJSON PlaneState
instance ToJSON CellChange
instance ToJSON Changes