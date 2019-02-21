{-# LANGUAGE DeriveGeneric #-}

module SnakeRepo
   ( SnakeId
   , SnakesMap
   , CommandResult
   , SnakesRepository
   , SnakeQualifiedEvent
   , SnakeRepoState(..)
   , SnakeQualifiedCmd(..)
   , applyCommand
   , initialRepo
   , repository
   , events
   , findAll
   , findAllKeys
   , snakeId
   , event
   , executeCommand
   , emptySnakesMap
   ) where

import qualified Data.Dequeue as Q
import qualified Data.Map     as Map (Map, elems, keys, empty, insert, lookup)
import           Data.Maybe
import           GHC.Generics
import           GHC.IORef
import qualified SnakeAggregate   as Aggr (applyCommand)
import qualified SnakeModel   as Snake
import Data.Aeson(ToJSON)

type SnakeId = String

type SnakesMap = Map.Map SnakeId Snake.SnakeData

data CommandResult = CommandResult
   { repository :: SnakesMap
   , events     :: [Snake.SnakeEvent]
   }

data SnakeQualifiedEvent = SnakeQualifiedEvent
   { snakeId :: SnakeId
   , event   :: Snake.SnakeEvent
   } deriving (Show, Generic, Eq)


data SnakeQualifiedCmd = SnakeQualifiedCmd String Snake.SnakeCommand

data SnakeRepoState = SnakeRepoState { repo        :: SnakesMap
   , eventsQueue :: Q.BankersDequeue SnakeQualifiedEvent
   }

type SnakesRepository = IORef SnakeRepoState

emptySnakesMap::SnakesMap
emptySnakesMap = Map.empty

initialRepo :: IO SnakesRepository
initialRepo = newIORef SnakeRepoState { repo = Map.empty, eventsQueue = Q.empty }

applyCommand :: SnakesMap -> SnakeId -> Snake.SnakeCommand -> CommandResult
applyCommand aMap uid cmd = CommandResult {repository = Map.insert uid newSnake aMap, events = snd applied}
  where
    oldSnakeMaybe = Map.lookup uid aMap
    oldSnake = fromMaybe Snake.initialSnake oldSnakeMaybe
    applied = Aggr.applyCommand oldSnake cmd
    newSnake = fst applied

findAll :: SnakesMap -> [Snake.SnakeData]
findAll aMap = Map.elems aMap

findAllKeys :: SnakeRepoState ->[SnakeId]
findAllKeys aRepo = Map.keys  $ repo aRepo


executeCommand :: SnakesRepository -> String -> Snake.SnakeCommand -> IO SnakeRepoState
executeCommand aRepo uidString aCmd = atomicModifyIORef aRepo (\g -> perform g uidString aCmd)


perform :: SnakeRepoState -> String -> Snake.SnakeCommand -> (SnakeRepoState, SnakeRepoState)
perform aRepoState uidString cmd = (newGame, newGame)
  where
    result = applyCommand oldRepository uidString cmd
    oldRepository = repo aRepoState
    newSnakeRepo = repository result
    newGame = SnakeRepoState {repo = newSnakeRepo, eventsQueue = newEventsQueue}
    oldEventsQueue = eventsQueue aRepoState
    newEvents = (\e -> SnakeQualifiedEvent {snakeId = uidString, event = e}) <$> (events result)
    newEventsQueue = foldl Q.pushFront oldEventsQueue newEvents

instance ToJSON SnakeQualifiedEvent