var mongodb = require('mongodb');
var MongoClient = mongodb.MongoClient;
var url = 'mongodb://localhost:27017,localhost:27018,localhost:27019/clusterdb?w=1&replicaSet=rs0&readPreference=secondaryPreferred';

MongoClient.connect(url, function (err, db) {
  if (err) {
    console.log('Unable to connect to the mongoDB server. Error:', err);
  }

  else {
    console.log('Connection established to', url);
    mainLoop(db);
  }
});

function mainLoop(db) {
  var collection = db.collection('clustercol');
  var readlineSync = require('readline-sync');

  var loop = function () {
    options = ['Insert', 'Query', 'Exit'],
    index = readlineSync.keyInSelect(options, 'What do you wanna do?', {cancel: false});

    if (options[index] == "Insert") {
      var textInfo = readlineSync.question('Type name to insert into collection: ');

      collection.insert({name: textInfo}, function (err, result) {
        if (err) {
          console.log(err);
        }
        else {
          console.log('Inserted %d documents into the "users" collection. The documents inserted with "_id" are:', result.length, result);
        }

        loop();
      });
    }

    else if (options[index] == "Query") {
      var textInfo = readlineSync.question('Type string to query from collection: ');

      collection.find({name: textInfo}).toArray(function (err, result) {
        if (err) {
          console.log(err);
        }
        else if (result.length) {
          console.log('Found:', result);
        }
        else {
          console.log('No document(s) found with defined "find" criteria!');
        }

        loop();
      });
    }

    else {
      console.log ('All done. See ya next time!');
      db.close();
      process.exit(0);
    }
  }

  loop();
}
