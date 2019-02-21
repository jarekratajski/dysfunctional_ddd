export interface SnakeCell {
   cellX :number;
   cellY: number;
}

export interface Plane {
  allCells:Array<CellPair>,
  changes: Changes
}

export interface PlaneCell {
  snakeCell : SnakeCell;
  cellType : CellType;
}


export interface CellType {
  tag: string;
  uid: string;
}

export type CellPair = Array<SnakeCell | PlaneCell>;


export  interface Changes {
  lastNr: number;
  history: any;
}

export interface CellChange {
  created: Array<PlaneCell>;
  destroyed: Array<PlaneCell>;
}