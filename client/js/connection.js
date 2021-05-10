// объект, в который помещаем данные для отправки
let fd = {
        pname: "createUser",
        p1: document.regname.regname.value,
        p2: document.regname.regpw.value,
        p3: null,
        p4: null
    }
    // console.log(fd);

function connectGame(params) {
    alert('it works!');

    fd.pname = "connectGame";
    fd.p1 = document.regname.regname.value;
    fd.p2 = document.regname.regpw.value;
    fd.p3 = document.container__list_of_games.querySelector('.list_of_games__btns').value;
    console.log(fd.p3);
    fd.p4 = null;

    // sendData(fd);
    document.querySelector('#game_options').style.display = "none";
    document.querySelector('#show_code').style.display = "flex";
}
// показываем публичные игры, которые есть
function showPublicGames(data) {
    console.log(data.length);
    if (data[0].err) {
        document.querySelector('.container__list_of_games__no_games').style.display = "flex";
    } else {
        for (let i = 0; i < data.length; i++) {
            let game = document.createElement('button');
            let creator = document.createElement('p');
            let size = document.createElement('p');
            let have_players = document.createElement('p');

            game.className = "play_submit list_of_games__btns";
            game.value = data[i].md;
            game.type = "button";
            game.onclick = "connectGame()";
            game.id = i;

            creator.className = "b_text";
            size.className = "b_text";
            have_players.className = "b_text";

            creator.innerText = data[i].creator;
            game.insertAdjacentElement("beforeend", creator);

            size.innerText = data[i].size;
            game.insertAdjacentElement("beforeend", size);

            have_players.innerText = data[i].have_players;
            game.insertAdjacentElement("beforeend", have_players);

            document.querySelector('.container__list_of_games').append(game);
        }
    }


}

// выводит пришедший код игрока на экран
function showCode(code) {
    // console.log(code);
    document.querySelector('.your_code__text').innerText = code;
}

// функция, которая смотрит, что за ответ пришел и решает, что с ним делать
function showAlert(data) {

    console.log("showAlert " + JSON.stringify(data));
    console.log(data[0].have_players);

    // смотрим, какие значения есть в ответе по нему ориентируемся, что нужно показать
    if (data[0].err != null) {
        alert(JSON.stringify(data));
    } else if (data[0].md) {
        showCode(data[0].md);
    }
    if (data[0].have_players != null) {
        showPublicGames(data);
    }
    // alert(JSON.stringify(p));
}

// функция создает акк игрока в бд
document.querySelector('#play_game').onclick = function() {
    fd.pname = "createUser";
    fd.p1 = document.regname.regname.value;
    fd.p2 = document.regname.regpw.value;
    fd.p3 = null;
    fd.p4 = null;
    sendData(fd);
    document.querySelector('#first_screen').style.display = "none";
    document.querySelector('#choose_btn').style.display = "flex";
    for (let i = 0; i < 2; i++) {

    }
    document.querySelector('.username').innerText = fd.p1;
}

// создание игры пользователем
document.querySelector('#create_game').onclick = function() {
    fd.pname = "createGame";
    fd.p1 = document.regname.regname.value;
    fd.p2 = document.regname.regpw.value;

    for (let i = 0; i < 2; i++) {
        if (document.choose_count_opponents.radio[i].checked) {
            fd.p3 = document.choose_count_opponents.radio[i].value;
        }
    }
    for (let i = 0; i < 2; i++) {
        if (document.choose_private_room.radio[i].checked) {
            fd.p4 = document.choose_private_room.radio[i].value;
        }
    }

    sendData(fd);
    document.querySelector('#game_options').style.display = "none";
    document.querySelector('#show_code').style.display = "flex";
}

// добавление пользователя в игру 
document.querySelector('#start_game').onclick = function() {
    fd.pname = "connectGame";
    fd.p1 = document.regname.regname.value;
    fd.p2 = document.regname.regpw.value;
    fd.p3 = document.enter_code_text.enter_code_text.value;
    fd.p4 = null;

    sendData(fd);
    document.querySelector('#enter_code').style.display = "none";
    document.querySelector('.game_wrapper').style.display = "flex";
}

// поиск публичных игр
document.querySelector('#find_game_btn').onclick = function() {
    fd.pname = "showPublicGames";
    fd.p1 = null;
    fd.p2 = null;
    fd.p3 = null;
    fd.p4 = null;

    sendData(fd);
    document.querySelector('#choose_btn').style.display = "none";
    document.querySelector('#list_of_games').style.display = "flex";
}

// отправляет данные на сервер
function sendData(fd) {
    fetch("http://localhost:3000", {
            method: 'POST',
            body: JSON.stringify(fd),
            headers: {
                'Content-Type': 'application/json'
            }
        }).then(response => {
            if (response.ok) {
                // let content = await response.text();
                // console.log(response.text());
                // console.log(response);
                // console.log(JSON.stringify(response));
                const Answer = response.json()
                console.log(Answer);
                return Answer;
            }
        })
        .then((data) => {
            console.log(data);
            showAlert(data);
        })
        .catch((error) => {
            console.error('Error:', error);
        });
}