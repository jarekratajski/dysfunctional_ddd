import {Game} from './game';
import {Plane, Changes} from './snake';

interface Registered {
  uid: string
}

export class Connection {
  private uid: string = "";

  constructor() {

  }

  setSnakeId(anId :string) {
    this.uid = anId;
  }

  register(nickName: string): Promise<string> {
    return fetch("/api/register",{method: 'POST'})
      .then(result => result.json() as Promise<Registered>)
      .then((data: Registered) => {
        this.uid = data.uid;

        return data.uid;
      });
  }

  setDirection(aDir: string) : Promise<string> {
    return fetch("/api/snakes/"+this.uid+"/dir", {method: 'POST', body : JSON.stringify({dir: aDir}) })
      .then ( data => JSON.stringify(data.json()));
  }


  debugProjectEvent() : Promise<any>{
    //return fetch("/api/projectSingle", {method: 'POST'}).then ( data => data.json());
    return fetch("/api/projectAll", {method: 'POST'}).then ( data => data.json());

  }

  debugMakeStep() {
    fetch("/api/step", {method: 'POST'})
      .then(result => result.json())
      .then(data => console.log('projectedEvents:' + JSON.stringify(data)));
  }

  getPlane(): Promise<Plane> {
    return fetch("/api/plane", {method: 'GET'})
      .then(result => result.json() as Promise<Plane>)
      .then(data => {
        //console.log('place:' + JSON.stringify(data));
        return data;
      });
  }
  getHistory(nr :Number): Promise<Changes> {
    return fetch("/api/history/"+nr, {method: 'GET'})
      .then(result => result.json() as Promise<Changes>)
      .then(data => {
        //console.log('place:' + JSON.stringify(data));
        return data;
      });
  }


}