let fd = {
        pname: "createUser",
        p1: document.regname.regname.value,
        p2: document.regname.regpw.value,
        p3: null,
        p4: null
    }
    // console.log(fd);
function showCode(code) {
    // console.log(code);
    document.querySelector('.your_code__text').innerText = code;
}

function showAlert(data) {
    // let res = JSON.parse(p.target.response);;
    // console.log(JSON.stringify(res));
    console.log("showAlert " + JSON.stringify(data));
    console.log(data[0].err);
    if (data[0].err != null) {
        alert(JSON.stringify(data));
    }
    if (data[0].md) {
        showCode(data[0].md);
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