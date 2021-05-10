// перемещение по меню

// pfrhsdftv jryj c ghbdtncndbtv b jnrhsdftv ghfdbkf
document.querySelector('#enter_game').onclick = function() {
    document.querySelector('#first_screen').style.display = "none";
    document.querySelector('.rules').style.display = "flex";
}

document.querySelector('#close_rules').onclick = function() {
    document.querySelector('#first_screen').style.display = "flex";
    document.querySelector('.rules').style.display = "none";
}

// document.querySelector('#play_game').onclick = function() {
//     document.querySelector('#first_screen').style.display = "none";
//     document.querySelector('#choose_btn').style.display = "flex";
// }

document.querySelector('#create_game_btn').onclick = function() {
    document.querySelector('#choose_btn').style.display = "none";
    document.querySelector('#game_options').style.display = "flex";
}

// document.querySelector('#find_game_btn').onclick = function() {
//     document.querySelector('#choose_btn').style.display = "none";
//     document.querySelector('#list_of_games').style.display = "flex";
// }

document.querySelector('#continue_game_btn').onclick = function() {
    document.querySelector('#choose_btn').style.display = "none";
    document.querySelector('.game_wrapper').style.display = "flex";
}

document.querySelector('#enter_code_btn').onclick = function() {
    document.querySelector('#choose_btn').style.display = "none";
    document.querySelector('#enter_code').style.display = "flex";
}

document.querySelector('#create_game_btn2').onclick = function() {
    document.querySelector('#list_of_games').style.display = "none";
    document.querySelector('#game_options').style.display = "flex";
}

// document.querySelector('#start_game').onclick = function() {
//     document.querySelector('#enter_code').style.display = "none";
//     document.querySelector('.game_wrapper').style.display = "flex";
// }

document.querySelector('#start_game_btn').onclick = function() {
    document.querySelector('#game_options').style.display = "none";
    document.querySelector('.game_wrapper').style.display = "flex";
}

document.querySelector('.arrow').onclick = function() {
    document.querySelector('#choose_btn').style.display = "none";

    document.querySelector('#first_screen').style.display = "flex";
}

document.querySelector('#arrow2').onclick = function() {
    document.querySelector('#game_options').style.display = "none";

    document.querySelector('#choose_btn').style.display = "flex";
}

document.querySelector('#arrow3').onclick = function() {
    document.querySelector('#enter_code').style.display = "none";

    document.querySelector('#choose_btn').style.display = "flex";
}

document.querySelector('#arrow4').onclick = function() {
    document.querySelector('#list_of_games').style.display = "none";
    document.querySelector('#choose_btn').style.display = "flex";
}