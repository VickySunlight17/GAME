// объект, в который помещаем данные для отправки
let info = {
        pname: "createUser",
        p1: document.regname.regname.value,
        p2: document.regname.regpw.value,
        p3: null,
        p4: null
    }
    // console.log(info);

// функия добавления игрока в игру из общего списка игр
document.querySelector('.container__list_of_games').onclick = function(event) {

        let target = event.target;
        console.log(target);

        alert('it works!');
        if (target.value == null) // если мы нажали не на кнопку,а на ее текст
        {
            info.p3 = target.parentNode.value;
        } else {
            info.p3 = target.value;
        }

        info.pname = "connectGame";
        info.p1 = document.regname.regname.value;
        info.p2 = document.regname.regpw.value;
        // info.p3 = target.value;
        console.log(info.p3);
        info.p4 = null;

        sendData(info);
        document.querySelector('#list_of_games').style.display = "none";
        document.querySelector('.game_wrapper').style.display = "flex";
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
            // let have_players = document.createElement('p');

            game.className = "play_submit list_of_games__btns";
            game.value = data[i].md;
            game.type = "button";
            game.onclick = "connectGame()";
            // game.id = i;

            creator.className = "b_text";
            size.className = "b_text";
            // have_players.className = "b_text";

            creator.innerText = data[i].creator;
            game.insertAdjacentElement("beforeend", creator);

            size.innerText = data[i].have_players + "/" + data[i].size;
            game.insertAdjacentElement("beforeend", size);

            // have_players.innerText = ;
            // game.insertAdjacentElement("beforeend", have_players);

            document.querySelector('.container__list_of_games').append(game);
        }
        console.log(document.querySelector('container__list_of_games'));
    }
}

// выводит пришедший код игрока на экран
function showCode(code) {
    // console.log(code);
    document.querySelector('.your_code__text').innerText = code;
}

function showGameInfoGet(data) {

    console.log(data);



    if (data[0].err) {
        alert(data[0].err);

    } else {
        // обнуляем значения запасов, чтобы при обновлении данных они отображались корректно
        for (let i = 0; i < 3; i++) {
            document.querySelectorAll('.cement')[i].style.visibility = "hidden";
            document.querySelectorAll('.grenade')[i].style.visibility = "hidden";
            document.querySelectorAll('.patron')[i].style.visibility = "hidden";
            document.querySelectorAll('.life')[i].style.visibility = "hidden";
        }

        for (let i = 0; i < data.length; i++) {

            switch (data[i].login) {

                case "cement":
                    {
                        let i = 0;
                        for (let elem of document.querySelectorAll('.cement')) {
                            // document.querySelectorAll('.life')[i].style.visibility = "visible";
                            elem.style.visibility = "visible";
                            if (i <= data[i].infoText) {
                                i++;
                            } else {
                                break;
                            }
                        }

                        break;
                    }
                case "grenade":
                    {
                        let i = 0;
                        for (let elem of document.querySelectorAll('.grenade')) {
                            // document.querySelectorAll('.life')[i].style.visibility = "visible";
                            elem.style.visibility = "visible";
                            if (i <= data[i].infoText) {
                                i++;
                            } else {
                                break;
                            }
                        }

                    }
                    break;

                case "patron":

                    {
                        let i = 0;
                        for (let elem of document.querySelectorAll('.patron')) {
                            // document.querySelectorAll('.life')[i].style.visibility = "visible";
                            elem.style.visibility = "visible";
                            if (i <= data[i].infoText) {
                                i++;
                            } else {
                                break;
                            }
                        }
                        break;
                    }
                case "lives":

                    {
                        let i = 0;
                        for (let elem of document.querySelectorAll('.life')) {
                            // document.querySelectorAll('.life')[i].style.visibility = "visible";
                            elem.style.visibility = "visible";
                            if (i <= data[i].infoText) {
                                i++;
                            } else {
                                break;
                            }
                        }
                        break;
                    }
                default:
                    {
                        // если эта строчка отвещает за 4 хода
                        if (data[i].moveTime == "moveLeft") {
                            console.log(data[i].moveTime);

                        } else {
                            // иначе создаем все сообщения сервера
                            let message = document.createElement('p');
                            let player = document.createElement('span');

                            message.className = "history_of_moves__answers__text";
                            player.className = "history_of_moves__answers__player";

                            message.innerText = data[i].infoText;
                            player.innerText = data[i].login + " ";
                            message.insertAdjacentElement("afterbegin", player);


                            document.querySelector('.history_of_moves__answers').append(message);

                        }

                        break;
                    }
            }
        }
    }
}


// функция, которая смотрит, что за ответ пришел и решает, что с ним делать
function serverResponse(data) {

    console.log("serverResponse " + JSON.stringify(data));
    // console.log(data[0].have_players);

    // смотрим, какие значения есть в ответе по нему ориентируемся, что нужно показать
    if (!data[0].err) {
        alert(JSON.stringify(data));
    } else if (data[0].md) {
        showCode(data[0].md);
    }

    if (data[0].have_players != null) {
        showPublicGames(data);
    }
    // если пришел ответ показать данные игры
    if (data[0].infoText) {
        showGameInfoGet(data);
    }
    //    (JSON.stringify(p));
}

// функция создает акк игрока в бд
document.querySelector('#play_game').onclick = function() {
    info.pname = "createUser";
    info.p1 = document.regname.regname.value;
    info.p2 = document.regname.regpw.value;
    info.p3 = null;
    info.p4 = null;
    sendData(info);
    document.querySelector('#first_screen').style.display = "none";
    document.querySelector('#choose_btn').style.display = "flex";

    for (let elem of document.querySelectorAll('.username')) {
        elem.innerText = document.regname.regname.value;

    }

}

// создание игры пользователем
document.querySelector('#create_game').onclick = function() {
    info.pname = "createGame";
    info.p1 = document.regname.regname.value;
    info.p2 = document.regname.regpw.value;

    for (let i = 0; i < 2; i++) {
        if (document.choose_count_opponents.radio[i].checked) {
            info.p3 = document.choose_count_opponents.radio[i].value;
        }
    }
    for (let i = 0; i < 2; i++) {
        if (document.choose_private_room.radio[i].checked) {
            info.p4 = document.choose_private_room.radio[i].value;
        }
    }

    sendData(info);
    document.querySelector('#game_options').style.display = "none";
    document.querySelector('#show_code').style.display = "flex";
}

// продолжение игры
document.querySelector('#continue_game_btn').onclick = function() {
        document.querySelector('#choose_btn').style.display = "none";
        document.querySelector('.game_wrapper').style.display = "flex";

        info.pname = "showGameInfo";
        info.p1 = document.regname.regname.value;
        info.p2 = document.regname.regpw.value;
        info.p3 = null;
        info.p4 = null;

        sendData(info);
    }
    // добавление пользователя в игру 
document.querySelector('#start_game').onclick = function() {
    info.pname = "connectGame";
    info.p1 = document.regname.regname.value;
    info.p2 = document.regname.regpw.value;
    info.p3 = document.enter_code_text.enter_code_text.value;
    info.p4 = null;

    sendData(info);
    document.querySelector('#enter_code').style.display = "none";
    document.querySelector('.game_wrapper').style.display = "flex";
}

// поиск публичных игр
document.querySelector('#find_game_btn').onclick = function() {
    info.pname = "showPublicGames";
    info.p1 = null;
    info.p2 = null;
    info.p3 = null;
    info.p4 = null;

    sendData(info);
    document.querySelector('#choose_btn').style.display = "none";
    document.querySelector('#list_of_games').style.display = "flex";
}

// отправляет данные на сервер
function sendData(info) {
    fetch("http://localhost:3000", {
            method: 'POST',
            body: JSON.stringify(info),
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
                    // console.log(Answer);
                return Answer;
            }
        })
        .then((data) => {
            console.log(data);
            serverResponse(data);
        })
        .catch((error) => {
            console.error('Error:', error);
        });
}