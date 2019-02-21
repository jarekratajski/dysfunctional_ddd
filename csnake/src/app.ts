import {Connection} from './connection';
import {Game} from './game';
import {Wonsz} from './wonsz';


/*for ( var i= 0; i < 10; i++ ) {
    drawWonsz( i + 5, 10 );

}
for ( var i= 0; i < 10; i++ ) {
    drawWonsz(  15,10+i);

}*/

//drawWonsz(50,50);


function prepareStart() {
  let connection = new Connection();
  let game = new Game(document, connection);
  let startButtons = document.getElementsByClassName('startGame');
  for (var i = 0; i < startButtons.length; i++) {
    (startButtons.item(i) as HTMLButtonElement).onclick = a => game.register('anyNick');
  }
  let oldUid = window.sessionStorage.getItem('snakeId');
  if (oldUid) {
    let contButtons = document.getElementsByClassName('contGame');
    for (var i = 0; i < contButtons.length; i++) {
      (contButtons.item(i) as HTMLButtonElement).onclick = a => game.continue();
    }
  }


  //window.setInterval(game.goForward, 200);
}


prepareStart();






