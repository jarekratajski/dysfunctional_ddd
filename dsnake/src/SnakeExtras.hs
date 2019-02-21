module SnakeExtras
   ( DirVector
   , dirVector
   , x
   , y
   , dirIs0
   , dirPlus
   ) where

import           SnakeModel

data DirVector = DirVector
   { x :: Int
   , y :: Int
   }

dirVector :: SnakeDirection -> DirVector
dirVector SnakeUp    = DirVector {x = 0, y = -1}
dirVector SnakeRight = DirVector {x = 1, y = 0}
dirVector SnakeDown  = DirVector {x = 0, y = 1}
dirVector SnakeLeft  = DirVector {x = -1, y = 0}

dirPlus :: DirVector -> DirVector -> DirVector
dirPlus DirVector {x = x1, y = y1} DirVector {x = x2, y = y2} = DirVector {x = x1 + x2, y = y1 + y2}

dirIs0 :: DirVector -> Bool
dirIs0 DirVector {x = 0, y = 0} = True
dirIs0 _                        = False
