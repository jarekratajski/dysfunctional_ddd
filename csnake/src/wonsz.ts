import {drawEtwas, maxHeight, maxWidth} from './draw';


export class Wonsz {
  x: number;
  y: number;
  direction: string = 'ArrowUp';
  wonszLength: number = 6;

  public segments: Array<Segment> = [];

  constructor(private allSnakes: Array<Wonsz>, private name: string) {
    this.x = maxWidth - 1;
    this.y = maxHeight - 1;
  }

  redraw() {
    //clearWonsz();
    //this.segments.forEach(s => s.redraw());
  }

  checkWonsz() {
    let zjedzon = this.allSnakes.find(s => s.hasSegment(this.x, this.y));
    if (zjedzon) {
      //updateGameState('gameOver');
      this.segments.forEach(s => s.remove());
      this.segments = [];
      this.wonszLength = 6;
    }


    let scoreOut = document.getElementsByClassName('score').item(0)
    scoreOut.textContent = '' + this.wonszLength;

  }

  addSegment() {
    if (this.x < 0) {
      this.x = maxWidth - 1;
    }
    if (this.x >= maxWidth) {
      this.x = 0;
    }
    if (this.y < 0) {
      this.y = maxHeight - 1;
    }
    if (this.y >= maxHeight) {
      this.y = 0;
    }
    this.checkWonsz();

    let newSegment = new Segment(this.x, this.y, this.name);
    this.segments.push(newSegment);
    if (this.segments.length >= this.wonszLength) {
      let removed = this.segments.shift();
      if (removed != null) {
        removed.remove();
      }
    }
  }

  moveUp() {
    this.y = this.y - 1;
    this.addSegment();
  }

  moveDown() {
    this.y = this.y + 1;
    this.addSegment();
  }

  moveLeft() {
    this.x = this.x - 1;
    this.addSegment();
  }

  moveRight() {
    this.x = this.x + 1;
    this.addSegment();
  }

  go() {
    switch (this.direction) {
      case 'ArrowUp': {
        this.moveUp();
        ;
        break;
      }
      case 'ArrowDown': {
        this.moveDown();
        ;
        break;
      }
      case 'ArrowLeft': {
        this.moveLeft();
        ;
        break;
      }
      case 'ArrowRight': {
        this.moveRight();
        ;
        break;
      }
    }


    this.redraw();
  }


  setDirection(key: string) {
    this.direction = key;
  }

  hasSegment(x: number, y: number): boolean {
    let zjedzon = this.segments.find(kawalWensza => (kawalWensza.x == x) && (kawalWensza.y == y));
    return zjedzon != null;

  }
}

function isOpposite(dir1: string, dir2: string) {
  return (dir1 == 'ArrowUp' && dir2 == 'ArrowDown')
    || (dir1 == 'ArrowLeft' && dir2 == 'ArrowRight');
}


class Segment {
  element: HTMLElement = null;

  constructor(public  x: number, public y: number, name: string) {
    this.element = drawEtwas(this.x, this.y, 'wonsz');
    this.element.classList.add(name);
  }

  remove() {
    this.element.remove();
  }
}





