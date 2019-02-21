{-# LANGUAGE DeriveGeneric #-}

module Game.State where

import           Data.Aeson      (ToJSON)
import qualified Data.Dequeue    as Q
import qualified Data.Foldable   as F
import           Data.UUID
import           Data.UUID.V4
import qualified Game.SnakePlane as Plane
import           GHC.Generics
import           GHC.IORef
import qualified SnakeModel      as Snake
import qualified SnakeRepo       as Repo
import Control.Monad

data Game = Game
   { snakeRepo :: Repo.SnakesRepository
   , plane     :: Plane.Plane
   }

data RegisterResult = RegisterResult
   { uid :: String
   } deriving (Show, Eq, Generic)

initialGameState :: IO Game
initialGameState = do
   aRepo <- Repo.initialRepo
   aPlane <- newIORef Plane.initialPlane
   return Game {snakeRepo = aRepo, plane = aPlane}

nextUid :: IO UUID
nextUid = nextRandom

{-
nextUid::IO UUID
nextUid _ =  do
                        cntRef <- counter
                        result <- atomicModifyIORef cntRef (\cnt -> (cnt+1, cnt+1))
                        return $ show result
-}
query :: ToJSON a => Game -> (Repo.SnakeRepoState -> a) -> IO a
query game f = fmap f (readIORef aSnakeRepo)
  where
    aSnakeRepo = snakeRepo game

performCommand :: Game -> String -> Snake.SnakeCommand -> IO Game
performCommand game uidString cmd = do
   _ <- Repo.executeCommand aSnakeRepo uidString cmd
   return game -- TODO we mutate
  where
    aSnakeRepo = snakeRepo game

{-
perform::GameState->String->Snake.SnakeCommand->(GameState, GameState)
perform game uidString cmd = (newGame, newGame)
         where
            result = Repo.applyCommand oldRepository uidString cmd
            oldRepository = repo game
            newSnakeRepo = Repo.repository result
            newGame = GameState { repo = newSnakeRepo, plane = plane game, eventsQueue = newEventsQueue}
            oldEventsQueue = eventsQueue game
            newEvents =  (\e -> Plane.SnakeQualifiedEvent{ Plane.snakeId  = uidString, Plane.event = e })  <$> (Repo.events result)
            newEventsQueue = foldl Q.pushFront oldEventsQueue newEvents
-}
registerPlayer :: Game -> String -> IO RegisterResult
registerPlayer game nick = do
   anUid <- nextUid
   let uidString = toString anUid
   planeState <- readIORef $ plane game
   let bestPlace = Plane.getBestPlaceForNextSnake planeState
   let cmd = Snake.Begin {Snake.initName = nick, Snake.initCell = bestPlace}
   _ <- performCommand game uidString cmd
                     -- let  result = Repo.applyCommand (repo gameState) uidString
                     -- let newGameState = GameState  { repo =Repo.repository result, plane = plane gameState}
   return (RegisterResult {uid = uidString})

changeDirection :: Game -> String -> Snake.SnakeDirection -> IO Game
changeDirection game snakeId direction = do
   let cmd = Snake.SetDirection {Snake.wantedDirection = direction}
   performCommand game snakeId cmd


makeAllSteps :: Game -> IO Game
makeAllSteps game = do
   snakes <- getSnakeIds game
   newGame <- foldM (\g s -> performCommand g s Snake.MakeStep) (game) snakes
   return newGame

getSnakes :: Game -> IO [Snake.SnakeData]
getSnakes game = query game (\g -> Repo.findAll $ Repo.repo g) --TODO use projection

getSnakeIds :: Game -> IO [Repo.SnakeId]
getSnakeIds game = query game (\g -> Repo.findAllKeys g) --TODO use projection

getEvents :: Game -> IO [Repo.SnakeQualifiedEvent]
getEvents game = query game (\g -> F.toList $ Repo.eventsQueue g)


projectSingleEvent :: Game -> IO (Maybe Repo.SnakeQualifiedEvent)
projectSingleEvent Game {snakeRepo = aSnakeRepo, plane = aPlane} = do
   newEvent <- atomicModifyIORef aSnakeRepo takeEvent
   putStrLn $ show newEvent
   res <- maybe (return (newEvent,[])) (\e -> atomicModifyIORef aPlane (\p -> planeApply p e)) newEvent
   let commands = snd res
   result <- foldl  (\r (Repo.SnakeQualifiedCmd cmdUid cmd )  ->  Repo.executeCommand aSnakeRepo cmdUid cmd >> r) ( return res) commands
   return $ fst result

projectAllEvents::Game -> IO (Maybe Repo.SnakeQualifiedEvent)
projectAllEvents game = do
            nextEvent <- projectSingleEvent game
            maybe (return Nothing)   (\_ ->  projectSingleEvent game) nextEvent


planeApply::Plane.PlaneState ->Repo.SnakeQualifiedEvent->(Plane.PlaneState, ( Maybe Repo.SnakeQualifiedEvent, [Repo.SnakeQualifiedCmd]))
planeApply aPlane e = (fst appResult, (Just e, snd appResult) )
      where
         appResult  = Plane.applyEvent aPlane e


takeEvent :: Repo.SnakeRepoState -> (Repo.SnakeRepoState, Maybe Repo.SnakeQualifiedEvent)
takeEvent aRepo@Repo.SnakeRepoState {} = maybe unchanged (\(a, b) -> (aRepo {Repo.eventsQueue = b}, Just a)) maybeEvent
  where
    aQueue = Repo.eventsQueue aRepo
    maybeEvent = Q.popBack aQueue
    unchanged = (aRepo, Nothing)

-- JSON
instance ToJSON RegisterResult
