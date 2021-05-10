<<<<<<< HEAD
let express = require('express');
const port = 3000;
let mysql = require('mysql');

var connection = mysql.createConnection({
    host: "localhost",
    user: "root",
    database: "labirint_game_project",
    password: "sinxro2000!"
});

connection.connect(function(err) {
    if (err) {
        return console.error("Ошибка: " + err.message);
    } else {
        console.log("Подключение к серверу MySQL успешно установлено");
    }
});

let app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use('/', express.static('client'));

app.post('/', function(request, response) {

    if (!request.body)
        return response.sendStatus(400);

    console.log(" Наши данные: " + JSON.stringify(request.body));

    let queryProcedure1 = `CALL ${request.body.pname}()`;
    let queryProcedure = `CALL ${request.body.pname}("${request.body.p1}", "${request.body.p2}")`;
    let queryProcedure3 = `CALL ${request.body.pname}("${request.body.p1}", "${request.body.p2}", "${request.body.p3}")`;
    let queryProcedure4 = `CALL ${request.body.pname}("${request.body.p1}", "${request.body.p2}", "${request.body.p3}", "${request.body.p4}")`;



    if (request.body.p4 != null) {
        connection.query(queryProcedure4, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    } else if (request.body.p3 != null) {
        connection.query(queryProcedure3, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    } else if (request.body.p2 != null) {
        connection.query(queryProcedure, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    } else if (request.body.p1 == null) {
        connection.query(queryProcedure1, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    }
});

app.get('/', function(_req, res) {
    res.sendFile(__dirname + "/client/index.html");
});

app.get('/error', function(_req, res) {
    res.sendFile(__dirname + "/client/error.html");
});

app.listen(port, function(err) {
    if (err) {
        return console.log('something bad happened', err);
    }
    console.log(`server is listening on ${port}...`);
=======
let express = require('express');
const port = 3000;
let mysql = require('mysql');

var connection = mysql.createConnection({
    host: "localhost",
    user: "root",
    database: "labirint_game_project",
    password: "sinxro2000!"
});

connection.connect(function(err) {
    if (err) {
        return console.error("Ошибка: " + err.message);
    } else {
        console.log("Подключение к серверу MySQL успешно установлено");
    }
});

let app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use('/', express.static('client'));

app.post('/', function(request, response) {

    if (!request.body)
        return response.sendStatus(400);

    console.log(" Наши данные: " + JSON.stringify(request.body));

    let queryProcedure1 = `CALL ${request.body.pname}()`;
    let queryProcedure = `CALL ${request.body.pname}("${request.body.p1}", "${request.body.p2}")`;
    let queryProcedure3 = `CALL ${request.body.pname}("${request.body.p1}", "${request.body.p2}", "${request.body.p3}")`;
    let queryProcedure4 = `CALL ${request.body.pname}("${request.body.p1}", "${request.body.p2}", "${request.body.p3}", "${request.body.p4}")`;



    if (request.body.p4 != null) {
        connection.query(queryProcedure4, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    } else if (request.body.p3 != null) {
        connection.query(queryProcedure3, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    } else if (request.body.p2 != null) {
        connection.query(queryProcedure, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    } else if (request.body.p1 == null) {
        connection.query(queryProcedure1, (err, res) => {
            if (err)
                throw err;
            console.log(res);
            response.send(res[0]);
        });
    }
});

app.get('/', function(_req, res) {
    res.sendFile(__dirname + "/client/index.html");
});

app.get('/error', function(_req, res) {
    res.sendFile(__dirname + "/client/error.html");
});

app.listen(port, function(err) {
    if (err) {
        return console.log('something bad happened', err);
    }
    console.log(`server is listening on ${port}...`);
>>>>>>> ab046d127beefb5a022e932174a6f3441abf78f0
});