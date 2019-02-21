{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE ViewPatterns      #-}

import           Control.Concurrent (forkIO, threadDelay)
import           Data.Aeson         (ToJSON, FromJSON)
import           Data.IORef
import           Data.Text          (Text, pack, unpack)
import qualified Data.Text.IO       as T
import           Data.UUID          (toString)
import qualified Database.Redis     as R
import qualified SnakeModel as Snake
import           Game.State
import           GHC.Generics
import           System.Periodic
import           Yesod
import qualified Game.SnakePlane as Plane

data App = App
   { visitors :: IORef Int
   }

mkYesod "Game" [parseRoutes|
/register RegisterR POST
/snakes/#Text/dir  ChangeDirR POST
/snakes SnakesR GET
/snakeIds SnakeIdsR GET
/events EventsR GET
/step MakeStepR POST
/projectSingle ProjectR POST
/projectAll ProjectAllR POST
/plane PlaneR GET
/history/#Int HistoryR GET
|]

instance Yesod Game

data Result = Result
   { status :: Text
   }

ok :: Result
ok = Result {status = "ok"}

instance ToJSON Result where
   toJSON Result {..} = object ["status" .= status]

data SetDirection = SetDirection
   { dir :: Snake.SnakeDirection
   } deriving (Show, Generic)

instance FromJSON SetDirection

postRegisterR :: Handler Value
postRegisterR = do
   gameRef <- getYesod
   -- gameRef <- fmap state getYesod
   -- cnt <- liftIO $ State.nextUid
   registered <- liftIO $ registerPlayer gameRef "aa"
   returnJson $ registered
   --returnJson $ Person (pack $ toString cnt) 77

getSnakesR :: Handler Value
getSnakesR = do
   gameRef <- getYesod
   snakes <- liftIO $ getSnakes gameRef
   returnJson $ snakes

getEventsR :: Handler Value
getEventsR = do
   gameRef <- getYesod
   snakes <- liftIO $ getEvents gameRef
   returnJson $ snakes

getSnakeIdsR :: Handler Value
getSnakeIdsR = do
   gameRef <- getYesod
   snakes <- liftIO $ getSnakeIds gameRef
   returnJson $ snakes

postMakeStepR :: Handler Value
postMakeStepR = do
   gameRef <- getYesod
   _ <- liftIO $ makeAllSteps gameRef
   returnJson $ ok

postProjectR :: Handler Value
postProjectR = do
   gameRef <- getYesod
   maybeEvent <- liftIO $ projectSingleEvent gameRef
   returnJson $ maybeEvent

postProjectAllR :: Handler Value
postProjectAllR = do
      gameRef <- getYesod
      maybeEvent <- liftIO $ projectAllEvents gameRef
      returnJson $ maybeEvent

postChangeDirR :: Text -> Handler Value
postChangeDirR aSnake = do
      direction <- requireJsonBody :: Handler SetDirection
      gameRef <- getYesod
      registered <- liftIO $ changeDirection gameRef snakeId ( dir direction )
      liftIO $ putStrLn $ "snakeID= " ++ snakeId ++ "]"
      returnJson $ dir direction
   where
      snakeId = unpack aSnake

getPlaneR :: Handler Value
getPlaneR = do
   gameRef <- getYesod
   aPlane <- liftIO $ readIORef  $ plane gameRef
   returnJson $ aPlane

getHistoryR::Int->Handler Value
getHistoryR lastVal = do
     gameRef <- getYesod
     aPlane <- liftIO $ readIORef  $ plane gameRef
     returnJson $ Plane.getHistory aPlane lastVal


main :: IO ()
main = do
   rconn <- R.connect R.defaultConnectInfo
   scheduler <-
      create (Name (pack "default")) rconn (CheckInterval (Seconds 1)) (LockTimeout (Seconds 1000)) (T.putStrLn)
   game <- initialGameState
   -- addTask scheduler "print-bye-job" (Every (Seconds 10)) (T.putStrLn "bye")
   _ <- forkIO (run scheduler)
   warp 3000 game
