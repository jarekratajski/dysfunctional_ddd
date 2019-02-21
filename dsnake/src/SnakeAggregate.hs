module SnakeAggregate (
    SnakeEventResult,
    applyCommand,
    executeCommand,
    applyEvent,
    applyEventX,
    newSnake,
    newCells,
    removedCells
)

      where

import           Data.List   (foldl)
import qualified SnakeExtras as V
import           SnakeModel

initialLength::Int
initialLength = 125


applyCommand :: SnakeData -> SnakeCommand -> (SnakeData, [SnakeEvent])
applyCommand snake cmd = (newSnakeData, events)
  where
    events = executeCommand snake cmd
    newSnakeData = foldl applyEvent snake events

executeCommand :: SnakeData -> SnakeCommand -> [SnakeEvent]
executeCommand SnakeData {state = Alive {}} MakeStep = [StepMade]
executeCommand _ MakeStep = []
executeCommand SnakeData {state = Alive {direction = od}} SetDirection {wantedDirection = nd}
   | isOpposite = []
   | otherwise = [DirectionChanged {newDirection = nd}]
  where
    isOpposite = V.dirIs0 $ V.dirPlus newVec currentVec
    newVec = V.dirVector nd
    currentVec = V.dirVector od
executeCommand _ SetDirection {} = []
executeCommand SnakeData {state = Alive {}} Die = [Killed]
executeCommand _ Die = []
executeCommand SnakeData {state = Init} Begin {initName = d, initCell = c} = [Born {bornName = d, bornCell = c}]
executeCommand _ Begin {} = []
-- executeCommand snake@SnakeData{ state = alive@Alive{}} Eat {}= []
executeCommand _ Eat{} = []


makeStep :: SnakeCell -> SnakeDirection -> SnakeCell
makeStep SnakeCell {cellX = x, cellY = y} dir = wrapCell SnakeCell {cellX = x + V.x vec, cellY = y + V.y vec}
  where
    vec = V.dirVector dir


data SnakeEventResult = SnakeEventResult {newSnake :: SnakeData,  newCells :: [SnakeCell] , removedCells :: [SnakeCell]}

applyEvent::SnakeData -> SnakeEvent -> SnakeData
applyEvent  snake event =  newSnake $ applyEventX  snake event

applyEventX :: SnakeData -> SnakeEvent -> SnakeEventResult
applyEventX snake@(SnakeData {state = alive@Alive {direction = d, cells = (c:_), maxLength = ml}}) StepMade =
   SnakeEventResult { newSnake  = SnakeData {name = name snake, state = newState}, newCells = [newCell], removedCells = dropped}
  where
    newState = alive {cells = newSnakeCells}
    newCell = makeStep c d
    totalCells = newCell : (cells $ state snake)
    dropped = drop ml totalCells
    newSnakeCells = take ml totalCells




applyEventX snake@(SnakeData {state = alive@Alive {}}) DirectionChanged { newDirection = nd }  =
      makeRes $ snake { state = alive{direction = nd} }
applyEventX snake@(SnakeData {state = Alive {}}) Killed = makeRes snake { state = Dead}
applyEventX SnakeData {state = Init} Born {bornName = nm, bornCell = cell} = SnakeEventResult {
            newSnake = SnakeData { name = nm , state = initialState },
               newCells = [cell], removedCells = []
      }
   where initialState = Alive { direction = SnakeUp, cells = [cell], maxLength = initialLength }
applyEventX snake@(SnakeData {state = alive@Alive {maxLength = n}})  HasEaten{} =
         makeRes snake { state = alive { maxLength = n+3} }
applyEventX _ _ = error "todo"

makeRes::SnakeData->SnakeEventResult
makeRes snake = SnakeEventResult { newSnake = snake, newCells = [], removedCells = []}


{-
action:
command -> events -> save -> propagate

action :: UUID -> SnakeCommand -> IO ()
action _ _ = error "aaa"
-}

wrapCell::SnakeCell->SnakeCell
wrapCell SnakeCell{cellX =x , cellY =y} = SnakeCell{cellX = nx, cellY = ny}
     where
            ny = wrapVal y (-100,100)
            nx = wrapVal x (-100, 100)

wrapVal::Int->(Int, Int)->Int
wrapVal value (minV, maxV)
      | value < minV = value + (maxV-minV)
      | value > maxV = value - (maxV-minV)
      | otherwise = value
