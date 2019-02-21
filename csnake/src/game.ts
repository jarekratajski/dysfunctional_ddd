import {Connection} from './connection';
import {drawEtwas, maxHeight, maxWidth} from './draw';
import {CellPair, Plane, PlaneCell, SnakeCell ,Changes, CellChange} from './snake';

let alternateKeys: any = {
  'w': 'ArrowUp',
  'a': 'ArrowLeft',
  's': 'ArrowDown',
  'd': 'ArrowRight'
};

class DrawnCell {
  cell: SnakeCell;
  value: PlaneCell;
  elem: HTMLElement;
}


export class Game {
  public gameState: string = 'start';

  private uid: string = null;
  private pgElement : HTMLElement = null;
  private lastHistory  = 0;
  //private visibleCells : Array<DrawnCell> = [];
  //in fact from Map (coord) -> DrawnCell
  private visibleMapping: any = {};


  constructor(private mainDocument: Document, private connection: Connection) {
    mainDocument.addEventListener('keydown', e => this.keyboardListener(e));
    this.pgElement = mainDocument.getElementById('playGround');
  }

  updateGameState(newState: string) {
    this.gameState = newState;
    console.log('game state is:' + this.gameState);
    let gameEl = this.mainDocument.getElementsByClassName('game').item(0);
    gameEl.setAttribute('data-state', this.gameState);
    if (this.gameState == 'play') {
      this.startRefreshing();
    }
  }

  singeRefresh() {
    if (this.gameState == 'play') {
        this.processHistory();
    }
  }

  private isSame(value: PlaneCell, cellValue: PlaneCell) {
    return JSON.stringify(value) === JSON.stringify(cellValue);
  }

  redrawUsingHistory(changes: Changes) {
    let lastHistoryNr = changes.lastNr;
    let history = changes.history;
    let keys = Object.keys(history) as Array<string>;
    keys.forEach ( aKey => {
        let cellChange = history[aKey] as CellChange;
        cellChange.destroyed.forEach (aCell => {
            let cellCoord = aCell.snakeCell;
            let coord = this.coordToString(cellCoord);
            let existingCell = this.visibleMapping[coord] as DrawnCell;
            if (existingCell) {
              existingCell.elem.remove();
              delete this.visibleMapping[coord];
            }
        });

      cellChange.created.forEach (aCell => {
        let cellCoord = aCell.snakeCell;
        let coord = this.coordToString(cellCoord);
        let existingCell = this.visibleMapping[coord] as DrawnCell;
        if (existingCell) {
          existingCell.elem.remove();
          delete this.visibleMapping[coord];
        }
        this.visibleMapping[coord] = this.drawCell(cellCoord, aCell);
      });
    });

    this.lastHistory = lastHistoryNr;
  }

  redrawCells(cells: Array<CellPair>) {
    //let cells = plane.allCells;
    //let oldCells = this.visibleCells;

    let oldKeys = Object.keys(this.visibleMapping) as Array<string>;
    let oldMapping = this.visibleMapping;


    cells.forEach((cellPair: Array<any>) => {
      let cellCoord = cellPair[0] as SnakeCell;
      let cellValue = cellPair[1] as PlaneCell;
      let coord = this.coordToString(cellCoord);
      let existingCell = oldMapping[coord] as DrawnCell;
      if (existingCell != null) {
        if (!this.isSame(existingCell.value, cellValue)) {
          existingCell.elem.remove();//todo ? and what?
          oldMapping[coord] = this.drawCell(cellCoord, cellValue);
        } else {
           //nuthing
        }


      } else {
        //we have new cell
        oldMapping[coord] = this.drawCell(cellCoord, cellValue);
      }
      oldKeys.forEach((item, index) => {
        if (item === coord) oldKeys.splice(index, 1);
      });
    });
    oldKeys.forEach((value: string, index: number) => {
      let toRemove = oldMapping[value] as DrawnCell;
      if (toRemove != null) {
        delete oldMapping[value];
        toRemove.elem.remove();
      }
    });
  }


  private drawCell(cellCoord: SnakeCell, cellValue: PlaneCell): DrawnCell {
    let drawnCell = new DrawnCell();
    drawnCell.cell = cellCoord;
    drawnCell.value = cellValue;
    let elem = drawEtwas(cellCoord.cellX, cellCoord.cellY, 'snake');
    if (this.isMy(cellValue)) {
      elem.classList.add('my');//todo  - who knows?
      this.scrollMe(cellCoord.cellX, cellCoord.cellY);
    } else {
      elem.classList.add('other');//todo  - who knows?
    }
    drawnCell.elem = elem;
    return drawnCell;
  }

  private coordToString(coord: SnakeCell) {
    return coord.cellX + "_" + coord.cellY;
  }

  register(nick: string) {
    this.connection.register(nick).then(anUid => {
      this.uid = anUid;
      window.sessionStorage.setItem('snakeId', anUid);
      this.updateGameState('play');
      //this.startRefreshing();
    })
  }

  continue() {
    let anUid = window.sessionStorage.getItem('snakeId');
    if (anUid) {
      this.uid = anUid;
      this.connection.setSnakeId(anUid);
      this.updateGameState('play');
      //this.startRefreshing();
    }
  }

  processPlane():Promise<any> {
    return this.connection.getPlane().then(aPlane => {
      this.redrawCells(aPlane.allCells);
      this.lastHistory = aPlane.changes.lastNr;
      return aPlane;
    });
  }

  processHistory():Promise<any> {
    return this.connection.getHistory(this.lastHistory+1).then(aHistory => {
    //  this.redrawCells(aPlane);
      this.redrawUsingHistory(aHistory)
      return aHistory;
    });
  }

  keyboardListener(e: KeyboardEvent) {
    console.log('key:' + e.key);
    console.log('code:' + e.code);
    let dwkey = alternateKeys[e.key] as string;
    if (dwkey) {
      e.stopPropagation();
      e.preventDefault();
      this.setDirection(dwkey);
    }
    if (e.key.startsWith('Arrow')) {
      e.stopPropagation();
      e.preventDefault();
      this.setDirection(e.key)
    }

    if (e.code == 'Enter') {
      this.connection.debugProjectEvent();
      e.stopPropagation();
      e.preventDefault();
    }

    if (e.code == 'Space') {
      this.connection.debugMakeStep();
      e.stopPropagation();
      e.preventDefault();
    }

    if (e.code == 'KeyP') {
      this.processPlane();
      e.stopPropagation();
      e.preventDefault();
    }

    if (e.code == 'KeyL') {
      this.auto();
      e.stopPropagation();
      e.preventDefault();
    }

    if (e.code == 'KeyR') {
      this.startRefreshing();
      e.stopPropagation();
      e.preventDefault();
    }

    if (e.code == 'KeyV') {
      this.updateGameState('play');
      e.stopPropagation();
      e.preventDefault();
    }

    if (e.code == 'KeyH') {
      this.processHistory();
      e.stopPropagation();
      e.preventDefault();
    }

    //

    return false;
  }

  private setDirection(key: string) {
    let cmd = key.replace("Arrow", "Snake");
    this.connection.setDirection(cmd)
      .then(data => console.log(data));
  }

  private procesEvents() {
    this.connection.debugProjectEvent().then(data => {
        if (data) {
          //console.log("continue...:"+data);
          if ( data !== 'null') {
            this.procesEvents();
            //console.log("event endedn null!");
          }
        } else {
          //console.log("event data was:" + data);
        }
      }
    );
  }

  private auto() {
    window.setInterval(() => {
      this.connection.debugMakeStep();
      this.procesEvents();
    }, 1000);
  }

  private startRefreshing() {
    this.processPlane().then ( res => {
      window.setInterval(() => {
        this.singeRefresh();
      }, 200);
    });

  }

  private isMy(cellValue: PlaneCell) {
    return cellValue.cellType.uid === this.uid;
  }

  private scrollMe(cellX: number, cellY: number) {
    let ax = -100 / maxWidth;
    let ay = -100 / maxHeight;
    let bx = 50;
    let by = 50;

    let anx = ax * cellX + bx;
    let any = ay * cellY + by;
    this.pgElement.setAttribute('style', `transform: translateX(${anx}%) translateY(${any}%);`);
  }
}


