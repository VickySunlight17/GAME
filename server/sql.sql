<<<<<<< HEAD
CREATE TABLE `players` (
 `login` varchar(30) NOT NULL,
 `password` varchar(50) NOT NULL,
 `indexNumber` INT(10) unsigned NOT NULL AUTO_INCREMENT,
 `game_id` INT(11) DEFAULT NULL,
 `lives` INT(11) DEFAULT NULL,
 `cement` INT(11) DEFAULT NULL,
 `patron` INT(11) DEFAULT NULL,
 `grenade` INT(11) DEFAULT NULL,
 `place` INT(11) DEFAULT NULL,
 PRIMARY KEY (`login`),
 UNIQUE KEY `loginNext` (`indexNumber`),
 KEY `game_id` (`game_id`),
 CONSTRAINT `users_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `game` (`game_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

CREATE TABLE gameInformation (
    game_id int,
    FOREIGN KEY (game_id) REFERENCES game(game_id) ON DELETE SET NULL,
 	login varchar(30) NOT NULL,
 	infoText varchar(100) NOT NULL
)
 
 /* таблица в которой лежат игроки,у которых есть право 4 внеочереднвх ходов */

CREATE TABLE moves4 (
    game_id int,
    FOREIGN KEY (game_id) REFERENCES game(game_id) ON DELETE SET NULL,
 	login varchar(30) NOT NULL,
 	movesLeft int default 4
)

-- создание пользователя игры
DELIMITER //
CREATE PROCEDURE createUser(   log VARCHAR(30),    pw VARCHAR(50))
BEGIN
        IF (SELECT COUNT(*) FROM players WHERE login=log) = 0 
        THEN
			INSERT INTO players VALUES(
    log, pw, NULL, NULL, NULL, NULL, NULL, NULL, NULL) ; 
		ELSE SELECT "Error! такой логин уже существует"   as err;
        
     END IF;
   END//
DELIMITER ;

-- выход игрока из бд
DELIMITER //
CREATE  PROCEDURE logout(log varchar(30), pw varchar(50))
BEGIN
	IF (SELECT COUNT(*) FROM players WHERE login=log) = 1 
		THEN
        IF (SELECT game_id FROM players WHERE login = log)!=NULL -- если игрок находится в игре
			THEN
				DELETE FROM players WHERE login=log AND password=pw;
            ELSE SELECT "Error! Ты находишься в игре. Сначала Выйди из нее и уже выходи из системы."   as err;     
    END IF;
	ELSE SELECT "Error! Такой логин не существует"   as err;     
    END IF;
    
   END//
DELIMITER ;

-- создание игрыю после авторизации юзера он создает игру и задает ей необходимые парамеры
-- создание игрыю после авторизации юзера он создает игру и задает ей необходимые парамеры
DROP PROCEDURE createGame;
DELIMITER //
CREATE  PROCEDURE createGame( log VARCHAR(30), pw VARCHAR(50), number INT, pblc boolean)
BEGIN
DECLARE x INT DEFAULT 0;
	IF EXISTS (SELECT * FROM players WHERE login=log AND password=pw)
	     THEN
         IF EXISTS (SELECT * FROM players WHERE login=log and game_id=NULL)
            THEN
         
                START TRANSACTION;
    	        INSERT INTO game(game_id, md, size, public, arsenal, robbers, treasure,	exitCell, directionExit, random) VALUES(NULL, NULL, number, pblc, NULL, NULL, NULL, NULL, NULL, rand()*1000000);
                SET x= last_insert_id();

                UPDATE game SET md=MD5(game_id) WHERE game_id=x; 
                UPDATE players SET game_id=x WHERE login=log ;
                INSERT INTO gameinformation(game_id, login, infoText) VALUES(x, log, "создал игру.");
  
                COMMIT;
-- UPDATE players SET inGame=1 WHERE login=log;

                SELECT md FROM game WHERE game_id=x ;   

        ELSE SELECT "Error! У пользователя уже есть game_id и он в игре."   as err;  
        END IF;
    ELSE SELECT "Error! неправильный логин/пароль"   as err;     
	END IF;
 
   END//
DELIMITER ;

-- подключение к игрею игроку присылают md игры и он к ней подключается

DELIMITER //
CREATE  PROCEDURE connectGame( log VARCHAR(30), pw VARCHAR(50), game_md VARCHAR(32))
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM game WHERE md=game_md);

IF id is not NULL -- если id не ноль (такая игра есть)
	THEN 
    IF EXISTS (SELECT * FROM players WHERE login=log AND password=pw) -- если такой игрок существует
	     THEN 
 IF (SELECT game_id FROM players WHERE login=log) is NULL
 THEN -- если этот игрок не находится в другой игре
 
 	IF ((SELECT size FROM game WHERE game_id=id)>(SELECT count(*) FROM players WHERE game_id=id)) -- если у нас нет нужного кол-ва игроков
        THEN    
       START TRANSACTION;
			UPDATE players SET game_id=id WHERE login=log;
   
      IF ((SELECT size FROM game WHERE game_id=id)=(SELECT count(*) FROM players WHERE game_id=id))
        THEN 
        	CALL createField(id);
            INSERT INTO moves VALUES ((SELECT login FROM players WHERE game_id=id and indexNumber=(SELECT min(indexNumber) FROM players WHERE game_id=id)), CURRENT_TIMESTAMP); 

            SELECT login, COUNT(*) as count FROM players WHERE game_id=id;
            
            COMMIT;
        ELSE
        	SELECT login, COUNT(*) as count FROM players WHERE game_id=id;
            COMMIT;
  	 END IF;
     
	ELSE SELECT "Error! неправильный game_id "   as err;
        
    END IF;
      
	ELSE SELECT "Error! у игрока уже есть id игры"   as err;
	END IF;
    
    ELSE SELECT "Error! неправильный логин пароль"   as err;

    END IF;
    
    ELSE SELECT "Error!, id игры равен NULL (connectGame)"   as err;
    END IF;
    
    
        
   END//
DELIMITER ;

-- DROP PROCEDURE `exitGame`; 
DELIMITER $$
CREATE PROCEDURE exitGame (log varchar(30), pw varchar(30))
BEGIN
DECLARE g_id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- ЕСЛИ ТАКОЙ ИГРОК СУЩЕСТВУЕТ
	THEN
		IF EXISTS (SELECT * FROM game WHERE game_id=g_id) -- ЕСЛИ ЕСТЬ ТАКАЯ ИГРА
           THEN
			IF ((SELECT size FROM game join players using (game_id) WHERE login=log and game.game_id=players.game_id)=(SELECT count(*) FROM players WHERE game_id=g_id)) -- проверяем, что кол-во игроков равно тому что в size - игра началась
				THEN
		
				START TRANSACTION;
				UPDATE players SET game_id=NULL, lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log; -- ОбНУЛЯЕМ ИГРОКА
				UPDATE game SET size=size-1 WHERE game_id=g_id; -- меняем кол-во игроков в игре, чтобы все хорошо считалосьъ
                INSERT INTO gameinformation(game_id, login, infoText) VALUES(g_id, log, " вышел из игры, остальным теперь легче бороться за Клад!");
 				COMMIT;
				call UPDATEMove(log, (SELECT random FROM game WHERE game_id=g_id));

			    IF ((SELECT count(*) FROM players WHERE game_id=g_id)=1) -- если игрок остался один
				    THEN
 
					    START TRANSACTION;
					    DELETE FROM game WHERE game_id=g_id; -- удаляем игру (game_id у игрока удаляется вместе с game_id у игры)
    				    UPDATE players SET lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log;
 					    COMMIT;       
    		    END IF;

		    ELSE 
			    START TRANSACTION;
			    UPDATE players SET game_id=Null, lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log;
                INSERT INTO gameinformation(game_id, login, infoText) VALUES(g_id, log, " вышел из игры, которая не нечалась!");			    
			    /* SELECT "Ты вышел из игры, которая не нечалась!"   as answer; */
			    COMMIT;       
		    END IF;

	    ELSE
		    SELECT "упс, кажется, такой игры нет!"  as err;
	    END IF;
ELSE
	SELECT "такого логина или пароля нет! Проверь написание и раскладку!"  as err;
END IF;
END $$

-- DROP PROCEDURE `exitGame`; 
-- DROP PROCEDURE `exitGame`; 
DELIMITER $$
CREATE PROCEDURE UPDATEMove(log varchar(30), random_num INT)
BEGIN
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
DECLARE lnext INT;

IF random_num=(SELECT random FROM game WHERE game_id=id)
    THEN -- если рандомное число совпадает с тем, что в игре

        IF EXISTS ( SELECT loginNext FROM players WHERE game_id=id AND loginNext>(SELECT loginNext FROM players WHERE login=log) LIMIT 1) -- если наш номер не максимальный в игре
            THEN 

                SET lnext=(SELECT loginNext FROM players WHERE game_id=id and loginNext>(SELECT loginNext FROM players WHERE login=log order by loginNext) limit 1); 
                           -- в переменную записываем значение
                UPDATE moves SET login = (SELECT login FROM players WHERE loginNext=lnext), active = CURRENT_TIMESTAMP WHERE login=log; -- меням порядок хода на следующего
                -- UPDATE moves SET active = CURRENT_TIMESTAMP WHERE login=log;
        ELSE -- иначе у нас макс номер игрока и мы должны просто поставить минимального
           
            SET lnext=(SELECT min(loginNext) FROM players WHERE game_id=id);
            UPDATE moves SET login=(SELECT login FROM players WHERE loginNext=lnext), active = CURRENT_TIMESTAMP WHERE login=log; -- меням порядок хода на следующего
            -- UPDATE moves SET active = CURRENT_TIMESTAMP WHERE login=log;
        END IF;   
ELSE 
    SELECT "Error, Вы пытаетесь вызвать функцию вне игры, так делать нельзя.(UPDATEmOVE)"   as err;
END IF;
END $$
DELIMITER ;

-- DROP PROCEDURE `showPublicGames`; 
DELIMITER $$
CREATE PROCEDURE showPublicGames()
BEGIN
	IF EXISTS (select * from game where public=1)     
        THEN
                                                  
            SELECT md, size, (select count(*) from players where game.game_id=players.game_id) as have_players, (select login from players WHERE game_id=game.game_id limit 1) FROM game WHERE public=1 and size>(select count(*) from players where game.game_id=players.game_id) GROUP BY game_id;                       
    ELSE
    SELECT "Sorry! Публичных игр пока нет! Создай свою с помощью createGame() (если ты вошел в систему, иначе войди с помощью createUser())" as err;
    END IF;
END $$
DELIMITER ;

-- функция удаления игры

DELIMITER //
CREATE  PROCEDURE endGame( g_id, rand_num)
BEGIN 

IF random_num=(SELECT random FROM game WHERE game_id=id)
    THEN -- если рандомное число совпадает с тем, что в игре

        DELETE FROM moves WHERE login=log; 
        UPDATE players SET lives=null, cement=null, patron=null, grenade=null, palce=null WHERE game_id=g_id;
        DELETE FROM game WHERE game_id=g_id;
 
        SELECT "Спасибо за игру!" as endgame ;
 
ELSE 
    SELECT "Данную функцию нельзя вызвать просто так! (endGame)" as err;
END IF;
            
END //
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE createField(id_of_game INT)
BEGIN 
-- DECLARE g_size INT DEFAULT(SELECT COUNT(*) FROM players WHERE game_id=id_of_game); -- посчитали ручками кол-во игроков, которые есть в игре	
	  
    IF EXISTS (SELECT * FROM game WHERE game_id=id_of_game)   -- если такая игра есть
    	THEN    
   			
			IF (SELECT COUNT(*) FROM players WHERE game_id=id_of_game)=(SELECT size FROM game WHERE game_id = id_of_game)
              	THEN
                
              		CREATE TEMPORARY TABLE result (login VARCHAR(30), num INT); -- временно храним расположение игроков/баз					
                    CREATE TEMPORARY TABLE tempPlayers (numbs INT PRIMARY KEY AUTO_INCREMENT, login VARCHAR(30)); -- временно храним игроков\базы         
                    CREATE TEMPORARY TABLE tempNnumbers (numbs INT PRIMARY KEY AUTO_INCREMENT, num INT); -- временно храним ячейки
                    INSERT INTO tempNnumbers(num) SELECT n FROM numbers ORDER BY rand() limit 10; -- вставляем рандомно рандомные числа в таблицу
               
                    INSERT INTO tempPlayers SELECT NULL, login FROM players WHERE game_id=id_of_game; -- вставляем логины игроков во врем таблицу
                    INSERT INTO tempPlayers(login) VALUES('arsenal'), ('robbers'),('treasure'); -- вставляем нужные предметы в таблицу
               
                    INSERT INTO result SELECT login, num FROM tempNnumbers NATURAL JOIN tempPlayers ; -- распределяем клетки между игроками
                         
                   UPDATE players SET place =(SELECT num FROM result WHERE result.login=players.login limit 1) WHERE game_id=id_of_game; -- расставляем местоположение игроков
                   UPDATE players SET lives=3, cement=3, patron=3, grenade=3, WHERE game_id=id_of_game;
                   UPDATE game SET robbers = (SELECT num FROM result WHERE login="robbers"), 
                   arsenal=(SELECT num FROM result WHERE login="arsenal"), 
                   treasure=(SELECT num FROM result WHERE login="treasure") WHERE game_id=id_of_game; -- добавляем все наши данные в игру
                   
                    UPDATE game SET exitCell=(SELECT wall FROM externalwalls ORDER BY rand() LIMIT 1) WHERE game_id=id_of_game;
                    UPDATE game SET directionExit=(SELECT directionWall FROM externalwalls, game WHERE wall=exitCell limit 1) WHERE game_id=id_of_game;
 
      ELSE SELECT "Error! Недостаточное кол-во игроков для создания поля."   as err;
     END IF; 
    
     ELSE 
 	    SELECT "Error! Sorry! Что-то сломалось и такого id игры нет!"  as err;
      END IF; 
   END
   $$
DELIMITER ;



INSERT INTO externalwalls (directionWall, wall) 
VALUES (4, 1), (1, 1),(1, 2),(1, 3),(1, 4),(1, 5),(2, 5),(4, 6),(2, 10),(4, 11),
(2, 15),(4, 16),(2, 20),(4, 21),(3, 21),(3, 22),(3, 23), (3, 24),(3, 25),(2, 25);

DELIMITER //
CREATE  PROCEDURE movePlayer( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
DECLARE newCell INT DEFAULT 0;

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
        IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
            THEN
                IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли жизни или нет
                    THEN
                        CASE direction
                        WHEN 1 -- когда шагаем вверх
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта и вынес Клад! Он победил!");
                                                    /* SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game; */
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта, но без Клада нельзя выйти");
                                                    /* SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer; */
                                                END IF;
                                        ELSE
                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался во внешнюю стену");
                                            /* SELECT log, " врезался во внешнюю стену" as answer;   */
                                        END IF;
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)-5;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)-5) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вверх и попал в арсенал");
                                            /* SELECT log, " прошел вверх и попал в арсенал" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вверх и нашел Клад");
                                            /* SELECT log, " прошел вверх и нашел Клад" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вверх и попался разбойникам");
                                            /* SELECT log, " прошел вверх и попался разбойникам" as answer; */
                                    ELSE 
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вверх");
                                        /* SELECT log, " прошел вверх" as answer; */
                                    END IF;
                                    END IF;

                        WHEN 2 -- когда шагаем вправо
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта и вынес Клад! Он победил!");
                                                    /* SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game; */
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта, но без Клада нельзя выйти");
                                                    /* SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer; */
                                                END IF;
                                        ELSE
                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался во внешнюю стену");
                                            /* SELECT log, " врезался во внешнюю стену" as answer; */
                                        END IF;

                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) AND directionWall=4) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)+1;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)+1) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вправо и попал в арсенал");
                                            /* SELECT log, " прошел вправо и попал в арсенал" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вправо и нашел Клад");
                                            /* SELECT log, " прошел вправо и нашел Клад" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вправо и попался разбойникам");
                                            /* SELECT log, " прошел вправо и попался разбойникам" as answer; */
                                    ELSE 
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вправо");
                                        /* SELECT log, " прошел вправо" as answer; */
                                    END IF; 
                                   END IF;
                        WHEN 3 -- когда шагаем вниз
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта и вынес Клад! Он победил!");
                                                    /* SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game; */
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта, но без Клада нельзя выйти");
                                                    /* SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer; */
                                                END IF;
                                        ELSE
                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался во внешнюю стену");
                                            /* SELECT log, " врезался во внешнюю стену" as answer; */
                                        END IF;

                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)+5;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)+5) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вниз и попал в арсенал");
                                            /* SELECT log, " прошел вниз и попал в арсенал" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вниз и нашел Клад");
                                            /* SELECT log, " прошел вниз и нашел Клад" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вниз и попался разбойникам");
                                            /* SELECT log, " прошел вниз и попался разбойникам" as answer; */
                                    ELSE 
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел вниз");
                                        /* SELECT log, " прошел вниз" as answer; */
                                    END IF;
  							 END IF;
                        WHEN 4 -- когда шагаем влево
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта и вынес Клад! Он победил!");
                                                    /* SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game; */
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " нашел Выход из лабиринта, но без Клада нельзя выйти");
                                                    /* SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer; */
                                                END IF;
                                        ELSE
                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался во внешнюю стену");
                                            /* SELECT log, " врезался во внешнюю стену" as answer; */
                                        END IF;

                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " врезался в стену");
                                        /* SELECT log, " врезался в стену" as answer; */
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)-1;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)-1) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел влево и попал в арсенал");
                                            /* SELECT log, " прошел влево и попал в арсенал" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел влево и нашел Клад");
                                            /* SELECT log, " прошел влево и нашел Клад" as answer; */
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел влево и попался разбойникам");
                                            /* SELECT log, " прошел влево и попался разбойникам" as answer; */
                                    ELSE 
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " прошел влево");
                                        /* SELECT log, " прошел влево" as answer; */
                                    END IF; 
							   END IF;
                        END CASE;
                         SELECT " move is ok" as answer;


                ELSE 
                    SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                END IF;
      
        ELSE 
            SELECT "error", "Упссс! Кажется, сейчас не твой ход!" as err;
        END IF; 

    ELSE 
        SELECT "error Куда идешь? Ты не в игре." as err;
    END IF;               
        
ELSE
	SELECT "error", "wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;

-- постройка стены

DELIMITER //
CREATE  PROCEDURE makeWall( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
DECLARE newCell INT DEFAULT 0;

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
                IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
                    THEN
                        IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли жизни или нет
                            THEN
                            IF (SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id) -- находимся ли мы в арсенале или нет
                                    THEN
                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать, но из арсенала нельзя взрывать стены");
                                        /* SELECT log, " пытался стрелять, но из арсенала нельзя взрывать стены" as answer; */
                                ELSE
                                IF (SELECT cement FROM players WHERE login=log)=0 -- есть ли цемент или нет
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но нет цемента");
                                        /* SELECT log, " пытался поставить стену, но нет цемента" as answer; */
                                ELSE
                                     
                                        CASE direction
                                            WHEN 1
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался замуровать что-то ОЧЕНЬ важное");
                                                                
                                                                    /* SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer; */
                                                            ELSE
                                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но уже есть внешняя");
                                                                /* SELECT log, " пытался поставить стену, но уже есть внешняя" as answer; */
                                                            END IF;


                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) AND game_id=id AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (1, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " поставил стену сверху от себя");
                                                        
                                                        /* SELECT log, " поставил стену сверху от себя" as answer; */
                                                    end IF;

                                            WHEN 2
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался замуровать что-то ОЧЕНЬ важное");
                                                                    /* SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer; */
                                                            ELSE
                                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но уже есть внешняя");
                                                                /* SELECT log, " пытался поставить стену, но уже есть внешняя" as answer; */
                                                            END IF;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) AND game_id=id  AND directionWall=4) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (2, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " поставил стену справа от себя");
                                                        /* SELECT log, " поставил стену справа от себя" as answer; */
                                                    end IF;
                                            
                                            WHEN 3
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался замуровать что-то ОЧЕНЬ важное");
                                                                    /* SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer; */
                                                            ELSE
                                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но уже есть внешняя");
                                                                /* SELECT log, " пытался поставить стену, но уже есть внешняя" as answer; */
                                                            END IF;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) AND game_id=id AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (3, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " поставил стену снизу от себя");
                                                        /* SELECT log, " поставил стену снизу от себя" as answer; */
                                                    end IF;

                                            WHEN 4
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался замуровать что-то ОЧЕНЬ важное");
                                                                    /* SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer; */
                                                            ELSE
                                                                INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но уже есть внешняя");
                                                                /* SELECT log, " пытался поставить стену, но уже есть внешняя" as answer; */
                                                            END IF;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) AND game_id=id  AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался поставить стену, но там уже есть");
                                                            /* SELECT log, " пытался поставить стену, но там уже есть" as answer; */
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (4, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " поставил стену слева от себя");
                                                        /* SELECT log, " поставил стену слева от себя" as answer; */
                                                    end IF;
                                        END CASE;
                                        SELECT "mwall is ok" as answer;

                                     END IF;       
                                END IF; 
                        ELSE 
                            SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                        END IF;
      
                ELSE 
                    SELECT "error Упссс! Кажется, сейчас не твой ход!" as err;
                END IF; 

        ELSE 
             SELECT "error Куда идешь? Ты не в игре." as err;
        END IF;               
        
ELSE
	SELECT "error wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;

-- взрыв стены
DELIMITER //
CREATE  PROCEDURE destroyWall( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
                IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
                    THEN
                        IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли жизни или нет
                            THEN
                            IF (SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id) -- находимся ли мы в арсенале или нет
                                    THEN
                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался стрелять, но из арсенала нельзя взрывать стены");
                                        /* SELECT log, " пытался стрелять, но из арсенала нельзя взрывать стены" as answer; */
                                        SELECT " dwall is ok" as answer;
                                ELSE
                                IF (SELECT grenade FROM players WHERE login=log)=0 -- есть ли цемент или нет
                                    THEN
                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но нет гранаты");
                                        /* SELECT log, " пытался взорвать стену, но нет гранаты" as answer; */
                                        SELECT " dwall is ok" as answer;
                                ELSE
                                     
                                        CASE direction
                                            WHEN 1    
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но она внешняя");
                                                            /* SELECT log, " пытался взорвать стену, но она внешняя" as answer; */

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                            DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) and directionWall=3 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену сверху от себя");
                                                            /* SELECT log, " взорвал стену сверху от себя" as answer; */
                                                            -- SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            
                                                            UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                            DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) and directionWall=3 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену сверху от себя");

                                                            /* SELECT log, " взорвал стену сверху от себя" as answer; */
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но там ее нет");
                                                        /* SELECT log, " пытался взорвать стену, но там ее нет" as answer; */
                                                    end IF;

                                            WHEN 2
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но она внешняя");
                                                            /* SELECT log, " пытался взорвать стену, но она внешняя" as answer; */

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) and directionWall=4 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену справа от себя");
                                                        /* SELECT log, " взорвал стену справа от себя" as answer; */
                                                         --   SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) AND directionWall=4) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) and directionWall=4 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену справа от себя");
                                                        /* SELECT log, " взорвал стену справа от себя" as answer; */
                                                         --   SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSE -- ЕСЛИ стены справа все таки нет
                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но там ее нет");
                                                        /* SELECT log, " пытался взорвать стену, но там ее нет" as answer; */
                                                    end IF;
                                            
                                            WHEN 3
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но она внешняя");
                                                            /* SELECT log, " пытался взорвать стену, но она внешняя" as answer; */

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) and directionWall=1 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену снизу от себя");
                                                        /* SELECT log, " взорвал стену снизу от себя" as answer; */
                                                            -- SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) and directionWall=1 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену снизу от себя");
                                                        /* SELECT log, " взорвал стену снизу от себя" as answer; */
                                                         --   SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSE -- ЕСЛИ стены снизу все таки нет
                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но там ее нет");
                                                        /* SELECT log, " пытался взорвать стену, но там ее нет" as answer; */
                                                    end IF;

                                            WHEN 4
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но она внешняя");
                                                            /* SELECT log, " пытался взорвать стену, но она внешняя" as answer; */

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) and directionWall=2 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену слева от себя");
                                                        /* SELECT log, " взорвал стену слева от себя" as answer; */
                                                            -- SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) and directionWall=2 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " взорвал стену слева от себя");
                                                        /* SELECT log, " взорвал стену слева от себя" as answer; */
                                                        --    SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но там ее нет");
                                                         /* SELECT log, " пытался взорвать стену, но там ее нет" as answer; */

                                                    end IF;
                                        END CASE;
                                            SELECT "dwall is ok" as answer;


                                     END IF;       
                                END IF;
                        ELSE 
                            SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                        END IF;
      
                ELSE 
                    SELECT "error", "Упссс! Кажется, сейчас не твой ход!" as err;
                END IF; 

        ELSE 
             SELECT "error Куда идешь? Ты не в игре." as err;
        END IF;               
        
ELSE
	SELECT "error", "wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;

CALL movePlayer("1","1", 1);
CALL shoot("1","1", 1);

-- стрельба 
/* НЕ РАБОТАЕТ:
уменьшается жизнь у стреляющего, а не у раненых
клад не удаляется у игрокаигрок не перемещается на место убитого
проблема в WHERE game_id=id and place=cell; */

DELIMITER //
CREATE  PROCEDURE shoot( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log); -- запоминаем id игры
DECLARE cell INT DEFAULT (SELECT place FROM players WHERE login=log); -- запоминаем расположение игрока

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
                IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
                    THEN
                        IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли жизни или нет
                            THEN
                                IF (SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id) -- находимся ли мы в арсенале или нет
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но нет гранаты");
                                        SELECT " shoot is ok" as answer;
                                ELSE

                                    IF (SELECT patron FROM players WHERE login=log)=0 -- есть ли цемент или нет
                                    THEN
                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " пытался взорвать стену, но нет гранаты");
                                        SELECT  " shoot is ok" as answer;
                                ELSE
                                     
                                        CASE direction
                                            WHEN 1    
                                                THEN
                                                   REPEAT
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                           INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вверх и ни в кого не попал");
                                                               /* SELECT log, " стрелял вверх и ни в кого не попал1" as answer; */
                                                               SET cell=0;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вверх и ни в кого не попал");
                                                                /* SELECT log, " стрелял вверх и ни в кого не попал2" as answer; */
                                                                SET cell=0;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell-5) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вверх и ни в кого не попал");
                                                                 /* SELECT log, " стрелял вверх и ни в кого не попал3" as answer; */
                                                                 SET cell=0;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=cell-- стоит ли на клетке выше игрок
                                                                THEN
                                                                    UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=NULL WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=1 WHERE login=log; -- помещаем клад себе
                                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока сверху от себя, отобрал его запасы, заполнил свои и забрал КЛАД");
                                                                            /* SELECT log, " попал в игрока сверху от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer; */
                                                                    ELSE
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока сверху от себя, отобрал его запасы и заполнил свои");                                                              
                                                                        /* SELECT log, " попал в игрока сверху от себя, отобрал его запасы и заполнил свои"  as answer; */
                                                                    END IF; 
                                                                    /* ВСТАВИТЬ ЧТО-ТО ПРО 4 ВНЕОЧЕРЕДНЫХ ХОДА */
                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    INSERT INTO moves4 (game_id, login, movesLeft) VALUES(id, log, 4);
                                                                    SET cell=0;                                                                 
                                                            ELSE 
                                                                SET cell=cell-5; -- идем еще на одну клетку наверх

                                                                IF (cell <5 )
                                                                    THEN
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вверх и ни в кого не попал");
                                                                        /* SELECT log, " стрелял вверх и ни в кого не попал4" as answer; */
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                    UNTIL cell <5 
                                                    END REPEAT;

                                                    /* SELECT log, " стрелял вверх и ни в кого не попал4" as answer; */
                                                    /* UPDATE players SET patron=patron-1  WHERE login=log; */

                                            WHEN 2
                                                THEN
                                                    REPEAT 
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                           INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вправо и ни в кого не попал");
                                                               /* SELECT log, " стрелял вправо и ни в кого не попал1" as answer; */
                                                               SET cell=5;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вправо и ни в кого не попал");
                                                                /* SELECT log, " стрелял вправо и ни в кого не попал2" as answer; */
                                                                SET cell=5;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell+1) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вправо и ни в кого не попал");
                                                                 /* SELECT log, " стрелял вправо и ни в кого не попал3" as answer; */
                                                                 SET cell=5;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=(cell)-- стоит ли на клетке правее игрок
                                                                THEN
                                                                   UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=false WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=true WHERE login=log; -- помещаем клад себе
                                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока вправа от себя, отобрал его запасы, заполнил свои и забрал КЛАД");
                                                                            /* SELECT log, " попал в игрока вправа от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer; */
                                                                    ELSE     
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока вправа от себя, отобрал его запасы и заполнил свои");                                                                   
                                                                        /* SELECT log, " попал в игрока вправа от себя, отобрал его запасы и заполнил свои"  as answer; */
                                                                    END IF; 

                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    INSERT INTO moves4 (game_id, login, movesLeft) VALUES(id, log, 4);
                                                                    SET cell=5;  
                                                                    /* SELECT " in to IF", cell ;                                                                   */
                                                            ELSE 
                                                                SET cell=cell+1; -- идем еще на одну клетку вправо

                                                                IF (cell=5 OR cell=10 OR cell=15 OR cell=20 OR cell=25)
                                                                    THEN
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вправо и ни в кого не попал");
                                                                        /* SELECT log, " стрелял вправо и ни в кого не попал4" as answer; */
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                        SELECT cell;
                                                    UNTIL (cell=5 OR cell=10 OR cell=15 OR cell=20 OR cell=25) 
                                                    END REPEAT;

                                                    /* SELECT log, " стрелял вправо и ни в кого не попал1" as answer; */
                                                    
                                            
                                            WHEN 3
                                                THEN
                                                    REPEAT 
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                           INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вниз и ни в кого не попал");
                                                               /* SELECT log, " стрелял вниз и ни в кого не попал1" as answer; */
                                                               SET cell=30;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вниз и ни в кого не попал");
                                                                /* SELECT log, " стрелял вниз и ни в кого не попал2" as answer; */
                                                                SET cell=30;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell+5) AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вниз и ни в кого не попал");
                                                                 /* SELECT log, " стрелял вниз и ни в кого не попал3" as answer; */
                                                                 SET cell=30;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=cell-- стоит ли на клетке ниже игрок
                                                                THEN
                                                                    UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=false WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=true WHERE login=log; -- помещаем клад себе
                                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока снизу от себя, отобрал его запасы, заполнил свои и забрал КЛАД");
                                                                            /* SELECT log, " попал в игрока снизу от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer; */
                                                                    ELSE     
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока снизу от себя, отобрал его запасы и заполнил свои");                                                                   
                                                                        /* SELECT log, " попал в игрока снизу от себя, отобрал его запасы и заполнил свои"  as answer; */
                                                                    END IF; 

                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    INSERT INTO moves4 (game_id, login, movesLeft) VALUES(id, log, 4);
                                                                    SET cell=30;                                                                    
                                                            ELSE 
                                                                SET cell=cell+5; -- идем еще на одну клетку наверх

                                                                IF (cell>21)
                                                                    THEN
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял вниз и ни в кого не попал");
                                                                        /* SELECT log, " стрелял вниз и ни в кого не попал4" as answer; */
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                        SELECT cell;
                                                    UNTIL cell>21
                                                    END REPEAT; 

                                                    /* SELECT log, " стрелял вниз и ни в кого не попал1" as answer; */
                                                    
                                            WHEN 4
                                                THEN
                                                    REPEAT 
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                           INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял влево и ни в кого не попал");
                                                               /* SELECT log, " стрелял влево и ни в кого не попал1" as answer; */
                                                               SET cell=1;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял влево и ни в кого не попал");
                                                                /* SELECT log, " стрелял влево и ни в кого не попал2" as answer; */
                                                                SET cell=1;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell-1) AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял влево и ни в кого не попал");
                                                                 /* SELECT log, " стрелял влево и ни в кого не попал3" as answer; */
                                                                 SET cell=1;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=cell-- стоит ли на клетке выше игрок
                                                                THEN
                                                                    UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=false WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=true WHERE login=log; -- помещаем клад себе
                                                                            INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока слева от себя, отобрал его запасы, заполнил свои и забрал КЛАД");
                                                                            /* SELECT log, " попал в игрока слева от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer; */
                                                                    ELSE                                                                        
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " попал в игрока слева от себя, отобрал его запасы и заполнил свои");
                                                                        /* SELECT log, " попал в игрока слева от себя, отобрал его запасы и заполнил свои"  as answer; */
                                                                    END IF; 

                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    INSERT INTO moves4 (game_id, login, movesLeft) VALUES(id, log, 4);
                                                                    SET cell=1;
                                                                    /* SELECT " in to IF", cell ;                                                                      */
                                                            ELSE 
                                                                SET cell=cell-1; -- идем еще на одну клетку наверх

                                                                IF (cell=1 OR cell=6 OR cell=11 OR cell=16 OR cell=21)
                                                                    THEN
                                                                    INSERT INTO gameinformation(game_id, login, infoText) VALUES(id, log, " стрелял влево и ни в кого не попал");
                                                                        /* SELECT log, " стрелял влево и ни в кого не попал4" as answer; */
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                        SELECT cell;
                                                    UNTIL (cell=1 OR cell=6 OR cell=11 OR cell=16 OR cell=21)
                                                    END REPEAT; 

                                                    /* SELECT log, " стрелял влево и ни в кого не попал1" as answer; */
                                        END CASE;
                                        SELECT " shoot is ok" as answer;
                                     END IF;       
                                END IF; 
                        ELSE 
                            SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                        END IF;
      
                ELSE 
                    SELECT "error", "Упссс! Кажется, сейчас не твой ход!" as err;
                END IF; 

        ELSE 
             SELECT "error Куда идешь? Ты не в игре." as err;
        END IF;               
        
ELSE
	SELECT "error", "wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE showGameInfo(log VARCHAR(30), pw VARCHAR(50))
BEGIN
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);

IF EXISTS (SELECT * FROM players WHERE login=log AND password=pw)
    THEN
        IF id IS NOT NULL -- если игрок находится в игре
            THEN        
                SELECT login, infoText FROM gameInformation where game_id=id 
                UNION 
                SELECT "cement", cement FROM players WHERE login=log 
                UNION 
                SELECT "grenade", grenade FROM players WHERE login=log
                UNION
                SELECT "lives", lives FROM players WHERE login=log
                UNION
                SELECT "patron", patron FROM players WHERE login=log
                UNION
                SELECT login, movesLeft FROM moves4 WHERE game_id=id;                 
        ELSE
	        SELECT "Ты не находишься в игре, чтобы смотреть ее процесс" as err;      
        END IF;        
ELSE
	SELECT "error, wrong log or pw" as err;      
END IF;

   end//
DELIMITER ;

CALL movePlayer("1","1", 1);
=======
CREATE TABLE `players` (
 `login` varchar(30) NOT NULL,
 `password` varchar(50) NOT NULL,
 `indexNumber` INT(10) unsigned NOT NULL AUTO_INCREMENT,
 `game_id` INT(11) DEFAULT NULL,
 `lives` INT(11) DEFAULT NULL,
 `cement` INT(11) DEFAULT NULL,
 `patron` INT(11) DEFAULT NULL,
 `grenade` INT(11) DEFAULT NULL,
 `place` INT(11) DEFAULT NULL,
 PRIMARY KEY (`login`),
 UNIQUE KEY `loginNext` (`indexNumber`),
 KEY `game_id` (`game_id`),
 CONSTRAINT `users_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `game` (`game_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- создание пользователя игры
DELIMITER //
CREATE PROCEDURE createUser(   log VARCHAR(30),    pw VARCHAR(50))
BEGIN
        IF (SELECT COUNT(*) FROM players WHERE login=log) = 0 
        THEN
			INSERT INTO players VALUES(
    log, pw, NULL, NULL, NULL, NULL, NULL, NULL, NULL) ; 
		ELSE SELECT "Error! такой логин уже существует"   as err;
        
     END IF;
   END//
DELIMITER ;

-- выход игрока из бд
DELIMITER //
CREATE  PROCEDURE logout(log varchar(30), pw varchar(50))
BEGIN
	IF (SELECT COUNT(*) FROM players WHERE login=log) = 1 
		THEN
        IF (SELECT game_id FROM players WHERE login = log)!=NULL -- если игрок находится в игре
			THEN
				DELETE FROM players WHERE login=log AND password=pw;
            ELSE SELECT "Error! Ты находишься в игре. Сначала Выйди из нее и уже выходи из системы."   as err;     
    END IF;
	ELSE SELECT "Error! Такой логин не существует"   as err;     
    END IF;
    
   END//
DELIMITER ;

-- создание игрыю после авторизации юзера он создает игру и задает ей необходимые парамеры
-- создание игрыю после авторизации юзера он создает игру и задает ей необходимые парамеры
DROP PROCEDURE createGame;
DELIMITER //
CREATE  PROCEDURE createGame( log VARCHAR(30), pw VARCHAR(50), number INT, pblc boolean)
BEGIN
DECLARE x INT DEFAULT 0;
	IF EXISTS (SELECT * FROM players WHERE login=log AND password=pw)
	     THEN
         IF EXISTS (SELECT * FROM players WHERE login=log and game_id=NULL)
            THEN
         
                START TRANSACTION;
    	        INSERT INTO game(game_id, md, size, public, arsenal, robbers, treasure,	exitCell, directionExit, random) VALUES(NULL, NULL, number, pblc, NULL, NULL, NULL, NULL, NULL, rand()*1000000);
                SET x= last_insert_id();

                UPDATE game SET md=MD5(game_id) WHERE game_id=x; 
                UPDATE players SET game_id=x WHERE login=log ;
                COMMIT;
-- UPDATE players SET inGame=1 WHERE login=log;

                SELECT md FROM game WHERE game_id=x ;   

        ELSE SELECT "Error! У пользователя уже есть game_id и он в игре."   as err;  
        END IF;
    ELSE SELECT "Error! неправильный логин/пароль"   as err;     
	END IF;
 
   END//
DELIMITER ;

-- подключение к игрею игроку присылают md игры и он к ней подключается

DELIMITER //
CREATE  PROCEDURE connectGame( log VARCHAR(30), pw VARCHAR(50), game_md VARCHAR(32))
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM game WHERE md=game_md);

IF id is not NULL -- если id не ноль (такая игра есть)
	THEN 
    IF EXISTS (SELECT * FROM players WHERE login=log AND password=pw) -- если такой игрок существует
	     THEN 
 IF (SELECT game_id FROM players WHERE login=log) is NULL
 THEN -- если этот игрок не находится в другой игре
 
 	IF ((SELECT size FROM game WHERE game_id=id)>(SELECT count(*) FROM players WHERE game_id=id)) -- если у нас нет нужного кол-ва игроков
        THEN    
       START TRANSACTION;
			UPDATE players SET game_id=id WHERE login=log;
   
      IF ((SELECT size FROM game WHERE game_id=id)=(SELECT count(*) FROM players WHERE game_id=id))
        THEN 
        	CALL createField(id);
            INSERT INTO moves VALUES ((SELECT login FROM players WHERE game_id=id and indexNumber=(SELECT min(indexNumber) FROM players WHERE game_id=id)), CURRENT_TIMESTAMP); 

            SELECT login, COUNT(*) as count FROM players WHERE game_id=id;
            
            COMMIT;
        ELSE
        	SELECT login, COUNT(*) as count FROM players WHERE game_id=id;
            COMMIT;
  	 END IF;
     
	ELSE SELECT "Error! неправильный game_id "   as err;
        
    END IF;
      
	ELSE SELECT "Error! у игрока уже есть id игры"   as err;
	END IF;
    
    ELSE SELECT "Error! неправильный логин пароль"   as err;

    END IF;
    
    ELSE SELECT "Error!, id игры равен NULL (connectGame)"   as err;
    END IF;
    
    
        
   END//
DELIMITER ;

-- DROP PROCEDURE `exitGame`; 
DELIMITER $$
CREATE PROCEDURE exitGame (log varchar(30), pw varchar(30))
BEGIN
DECLARE g_id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- ЕСЛИ ТАКОЙ ИГРОК СУЩЕСТВУЕТ
	THEN
		IF EXISTS (SELECT * FROM game WHERE game_id=g_id) -- ЕСЛИ ЕСТЬ ТАКАЯ ИГРА
           THEN
			IF ((SELECT size FROM game join players using (game_id) WHERE login=log and game.game_id=players.game_id)=(SELECT count(*) FROM players WHERE game_id=g_id)) -- проверяем, что кол-во игроков равно тому что в size - игра началась
				THEN
		
				START TRANSACTION;
				UPDATE players SET game_id=NULL, lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log; -- ОбНУЛЯЕМ ИГРОКА
				UPDATE game SET size=size-1 WHERE game_id=g_id; -- меняем кол-во игроков в игре, чтобы все хорошо считалосьъ
 				COMMIT;
				call UPDATEMove(log, (SELECT random FROM game WHERE game_id=g_id));

			    IF ((SELECT count(*) FROM players WHERE game_id=g_id)=1) -- если игрок остался один
				    THEN
 
					    START TRANSACTION;
					    DELETE FROM game WHERE game_id=g_id; -- удаляем игру (game_id у игрока удаляется вместе с game_id у игры)
    				    UPDATE players SET lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log;
 					    COMMIT;
       
    		    END IF;
		    ELSE 
			    START TRANSACTION;
			    UPDATE players SET game_id=Null, lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log;			    
			    SELECT "Ты вышел из игры, которая не нечалась!"   as answer;
			    COMMIT;       
		    END IF;

	    ELSE
		    SELECT "упс, кажется, такой игры нет!"  as err;
	    END IF;
ELSE
	SELECT "такого логина или пароля нет! Проверь написание и раскладку!"  as err;
END IF;
END $$

-- DROP PROCEDURE `exitGame`; 
-- DROP PROCEDURE `exitGame`; 
DELIMITER $$
CREATE PROCEDURE UPDATEMove(log varchar(30), random_num INT)
BEGIN
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
DECLARE lnext INT;

IF random_num=(SELECT random FROM game WHERE game_id=id)
    THEN -- если рандомное число совпадает с тем, что в игре

        IF EXISTS ( SELECT loginNext FROM players WHERE game_id=id AND loginNext>(SELECT loginNext FROM players WHERE login=log) LIMIT 1) -- если наш номер не максимальный в игре
            THEN 

                SET lnext=(SELECT loginNext FROM players WHERE game_id=id and loginNext>(SELECT loginNext FROM players WHERE login=log order by loginNext) limit 1); 
                           -- в переменную записываем значение
                UPDATE moves SET login = (SELECT login FROM players WHERE loginNext=lnext), active = CURRENT_TIMESTAMP WHERE login=log; -- меням порядок хода на следующего
                -- UPDATE moves SET active = CURRENT_TIMESTAMP WHERE login=log;
        ELSE -- иначе у нас макс номер игрока и мы должны просто поставить минимального
           
            SET lnext=(SELECT min(loginNext) FROM players WHERE game_id=id);
            UPDATE moves SET login=(SELECT login FROM players WHERE loginNext=lnext), active = CURRENT_TIMESTAMP WHERE login=log; -- меням порядок хода на следующего
            -- UPDATE moves SET active = CURRENT_TIMESTAMP WHERE login=log;
        END IF;   
ELSE 
    SELECT "Error, Вы пытаетесь вызвать функцию вне игры, так делать нельзя.(UPDATEmOVE)"   as err;
END IF;
END $$
DELIMITER ;

-- DROP PROCEDURE `showPublicGames`; 
DELIMITER $$
CREATE PROCEDURE showPublicGames()
BEGIN
	IF EXISTS (select * from game where public=1)     
        THEN
                                                  
            SELECT md, size, (select count(*) from players where game.game_id=players.game_id) as have_players, (select login from players WHERE game_id=game.game_id limit 1) FROM game WHERE public=1 and size>(select count(*) from players where game.game_id=players.game_id) GROUP BY game_id;                       
    ELSE
    SELECT "Sorry! Публичных игр пока нет! Создай свою с помощью createGame() (если ты вошел в систему, иначе войди с помощью createUser())" as err;
    END IF;
END $$
DELIMITER ;

-- функция удаления игры

DELIMITER //
CREATE  PROCEDURE endGame( g_id, rand_num)
BEGIN 

IF random_num=(SELECT random FROM game WHERE game_id=id)
    THEN -- если рандомное число совпадает с тем, что в игре

        DELETE FROM moves WHERE login=log; 
        UPDATE players SET lives=null, cement=null, patron=null, grenade=null, palce=null WHERE game_id=g_id;
        DELETE FROM game WHERE game_id=g_id;
 
        SELECT "Спасибо за игру!" as endgame ;
 
ELSE 
    SELECT "Данную функцию нельзя вызвать просто так! (endGame)" as err;
END IF;
            
END //
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE createField(id_of_game INT)
BEGIN 
-- DECLARE g_size INT DEFAULT(SELECT COUNT(*) FROM players WHERE game_id=id_of_game); -- посчитали ручками кол-во игроков, которые есть в игре	
	  
    IF EXISTS (SELECT * FROM game WHERE game_id=id_of_game)   -- если такая игра есть
    	THEN    
   			
			IF (SELECT COUNT(*) FROM players WHERE game_id=id_of_game)=(SELECT size FROM game WHERE game_id = id_of_game)
              	THEN
                
              		CREATE TEMPORARY TABLE result (login VARCHAR(30), num INT); -- временно храним расположение игроков/баз					
                    CREATE TEMPORARY TABLE tempPlayers (numbs INT PRIMARY KEY AUTO_INCREMENT, login VARCHAR(30)); -- временно храним игроков\базы         
                    CREATE TEMPORARY TABLE tempNnumbers (numbs INT PRIMARY KEY AUTO_INCREMENT, num INT); -- временно храним ячейки
                    INSERT INTO tempNnumbers(num) SELECT n FROM numbers ORDER BY rand() limit 10; -- вставляем рандомно рандомные числа в таблицу
               
                    INSERT INTO tempPlayers SELECT NULL, login FROM players WHERE game_id=id_of_game; -- вставляем логины игроков во врем таблицу
                    INSERT INTO tempPlayers(login) VALUES('arsenal'), ('robbers'),('treasure'); -- вставляем нужные предметы в таблицу
               
                    INSERT INTO result SELECT login, num FROM tempNnumbers NATURAL JOIN tempPlayers ; -- распределяем клетки между игроками
                         
                   UPDATE players SET place =(SELECT num FROM result WHERE result.login=players.login limit 1) WHERE game_id=id_of_game; -- расставляем местоположение игроков
                   UPDATE players SET lives=3, cement=3, patron=3, grenade=3, WHERE game_id=id_of_game;
                   UPDATE game SET robbers = (SELECT num FROM result WHERE login="robbers"), 
                   arsenal=(SELECT num FROM result WHERE login="arsenal"), 
                   treasure=(SELECT num FROM result WHERE login="treasure") WHERE game_id=id_of_game; -- добавляем все наши данные в игру
                   
                    UPDATE game SET exitCell=(SELECT wall FROM externalwalls ORDER BY rand() LIMIT 1) WHERE game_id=id_of_game;
                    UPDATE game SET directionExit=(SELECT directionWall FROM externalwalls, game WHERE wall=exitCell limit 1) WHERE game_id=id_of_game;
 
      ELSE SELECT "Error! Недостаточное кол-во игроков для создания поля."   as err;
     END IF; 
    
     ELSE 
 	    SELECT "Error! Sorry! Что-то сломалось и такого id игры нет!"  as err;
      END IF; 
   END
   $$
DELIMITER ;



INSERT INTO externalwalls (directionWall, wall) 
VALUES (4, 1), (1, 1),(1, 2),(1, 3),(1, 4),(1, 5),(2, 5),(4, 6),(2, 10),(4, 11),
(2, 15),(4, 16),(2, 20),(4, 21),(3, 21),(3, 22),(3, 23), (3, 24),(3, 25),(2, 25);

DELIMITER //
CREATE  PROCEDURE movePlayer( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
DECLARE newCell INT DEFAULT 0;

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
        IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
            THEN
                IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли изни или нет
                    THEN
                        CASE direction
                        WHEN 1 -- когда шагаем вверх
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                    SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game;
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                    SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer;
                                                END IF;
                                        ELSE
                                            SELECT log, " врезался во внешнюю стену" as answer;  
                                        END IF;
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)-5;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)-5) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            SELECT log, " прошел вверх и попал в арсенал" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            SELECT log, " прошел вверх и нашел Клад" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            SELECT log, " прошел вверх и попался разбойникам" as answer;
                                    ELSE 
                                        SELECT log, " прошел вверх" as answer;
                                    END IF;
                                    END IF;

                        WHEN 2 -- когда шагаем вправо
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                    SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game;
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                    SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer;
                                                END IF;
                                        ELSE
                                            SELECT log, " врезался во внешнюю стену" as answer;
                                        END IF;

                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) AND directionWall=4) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)+1;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)+1) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            SELECT log, " прошел вправо и попал в арсенал" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            SELECT log, " прошел вправо и нашел Клад" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            SELECT log, " прошел вправо и попался разбойникам" as answer;
                                    ELSE 
                                        SELECT log, " прошел вправо" as answer;
                                    END IF; 
                                   END IF;
                        WHEN 3 -- когда шагаем вниз
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                    SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game;
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                    SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer;
                                                END IF;
                                        ELSE
                                            SELECT log, " врезался во внешнюю стену" as answer;
                                        END IF;

                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)+5;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)+5) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            SELECT log, " прошел вниз и попал в арсенал" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            SELECT log, " прошел вниз и нашел Клад" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            SELECT log, " прошел вниз и попался разбойникам" as answer;
                                    ELSE 
                                        SELECT log, " прошел вниз" as answer;
                                    END IF;
  							 END IF;
                        WHEN 4 -- когда шагаем влево
                            THEN
                                IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняяли стена
                                    THEN
                                        IF (SELECT directionExit FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                            THEN
                                                IF (SELECT haveTreasure FROM players WHERE login=log)=true -- если мы наткнулись на выход, а у нас с собой еще и клад есть
                                                THEN
                                                    SELECT log, " нашел Выход из лабиринта и вынес Клад! Он победил!" as end_of_game;
                                                    CALL endGame(id, (SELECT random from game WHERE game_id=id)); -- вызываем функцию для выхода всех игроков из игры
                                                ELSE
                                                    SELECT log, " нашел Выход из лабиринта, но без Клада нельзя выйти" as answer;
                                                END IF;
                                        ELSE
                                            SELECT log, " врезался во внешнюю стену" as answer;
                                        END IF;

                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                    THEN
                                        SELECT log, " врезался в стену" as answer;
                                ELSE -- ЕСЛИ МЫ ЧУДОМ НЕ НАТКНУЛИСЬ НИ НА ОДНУ ИЗ СТЕН

                                    SET newCell=(SELECT place FROM players WHERE login=log)-1;
                                    UPDATE players SET place=((SELECT place FROM players WHERE login=log)-1) WHERE login=log; -- ОбНОВЛЯЕМ НАШЕ НОВОЕ МЕСТОПОЛОжЕНИЕ

                                    IF ((SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК ОКАЗАЛСЯ В АРСЕНАЛЕ
                                        THEN
                                            UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log;
                                            SELECT log, " прошел влево и попал в арсенал" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT treasure FROM game WHERE game_id=id)) -- ЕСЛИ ИГРОК НАШЕЛ КЛАД
                                        THEN 
                                            UPDATE players SET haveTreasure=true WHERE login=log;
                                            SELECT log, " прошел влево и нашел Клад" as answer;
                                    ELSEIF ((SELECT place FROM players WHERE login=log)=(SELECT robbers FROM game WHERE game_id=id)) -- если игрок наткнулся на разбойников
                                        THEN
                                            UPDATE players SET cement=0, patron=0, grenade=0, haveTreasure=false WHERE login=log;
                                            SELECT log, " прошел влево и попался разбойникам" as answer;
                                    ELSE 
                                        SELECT log, " прошел влево" as answer;
                                    END IF; 
							   END IF;
                        END CASE;


                ELSE 
                    SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                END IF;
      
        ELSE 
            SELECT "error", "Упссс! Кажется, сейчас не твой ход!" as err;
        END IF; 

    ELSE 
        SELECT "error Куда идешь? Ты не в игре." as err;
    END IF;               
        
ELSE
	SELECT "error", "wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;

-- постройка стены

DELIMITER //
CREATE  PROCEDURE makeWall( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);
DECLARE newCell INT DEFAULT 0;

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
                IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
                    THEN
                        IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли жизни или нет
                            THEN
                            IF (SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id) -- находимся ли мы в арсенале или нет
                                    THEN
                                        SELECT log, " пытался стрелять, но из арсенала нельзя взрывать стены" as answer;
                                ELSE
                                IF (SELECT cement FROM players WHERE login=log)=0 -- есть ли цемент или нет
                                    THEN
                                        SELECT log, " пытался поставить стену, но нет цемента" as answer;
                                ELSE
                                     
                                        CASE direction
                                            WHEN 1
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                    SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer;
                                                            ELSE
                                                                SELECT log, " пытался поставить стену, но уже есть внешняя" as answer;
                                                            END IF;


                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) AND game_id=id AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (1, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        SELECT log, " поставил стену сверху от себя" as answer;
                                                    end IF;

                                            WHEN 2
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                    SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer;
                                                            ELSE
                                                                SELECT log, " пытался поставить стену, но уже есть внешняя" as answer;
                                                            END IF;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) AND game_id=id  AND directionWall=4) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (2, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        SELECT log, " поставил стену справа от себя" as answer;
                                                    end IF;
                                            
                                            WHEN 3
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                    SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer;
                                                            ELSE
                                                                SELECT log, " пытался поставить стену, но уже есть внешняя" as answer;
                                                            END IF;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) AND game_id=id AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (3, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        SELECT log, " поставил стену снизу от себя" as answer;
                                                    end IF;

                                            WHEN 4
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            IF (SELECT direction FROM game WHERE exitCell=(SELECT place FROM players WHERE login=log) AND game_id=id)=direction -- проверяем не выход ли это случайно
                                                                THEN
                                                                    SELECT log, " пытался замуровать что-то ОЧЕНЬ важное" as answer;
                                                            ELSE
                                                                SELECT log, " пытался поставить стену, но уже есть внешняя" as answer;
                                                            END IF;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND game_id=id   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) AND game_id=id  AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            SELECT log, " пытался поставить стену, но там уже есть" as answer;
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        UPDATE players SET cement=cement-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        INSERT INTO walls(directionWall, game_id, wall) VALUES (4, id, (SELECT place FROM players WHERE login=log)); -- добавляем нашу стену в общий список стен
                                                        SELECT log, " поставил стену слева от себя" as answer;
                                                    end IF;
                                        END CASE;

                                     END IF;       
                                END IF; 
                        ELSE 
                            SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                        END IF;
      
                ELSE 
                    SELECT "error Упссс! Кажется, сейчас не твой ход!" as err;
                END IF; 

        ELSE 
             SELECT "error Куда идешь? Ты не в игре." as err;
        END IF;               
        
ELSE
	SELECT "error wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;

-- взрыв стены
DELIMITER //
CREATE  PROCEDURE destroyWall( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log);

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
                IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
                    THEN
                        IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли жизни или нет
                            THEN
                            IF (SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id) -- находимся ли мы в арсенале или нет
                                    THEN
                                        SELECT log, " пытался стрелять, но из арсенала нельзя взрывать стены" as answer;
                                ELSE
                                IF (SELECT grenade FROM players WHERE login=log)=0 -- есть ли цемент или нет
                                    THEN
                                        SELECT log, " пытался взорвать стену, но нет гранаты" as answer;
                                ELSE
                                     
                                        CASE direction
                                            WHEN 1    
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            SELECT log, " пытался взорвать стену, но она внешняя" as answer;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                            DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) and directionWall=3 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            SELECT log, " взорвал стену сверху от себя" as answer;
                                                            -- SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                            
                                                            UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                            DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-5) and directionWall=3 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                            SELECT log, " взорвал стену сверху от себя" as answer;
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                        SELECT log, " пытался взорвать стену, но там ее нет" as answer;
                                                    end IF;

                                            WHEN 2
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            SELECT log, " пытался взорвать стену, но она внешняя" as answer;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) and directionWall=4 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        SELECT log, " взорвал стену справа от себя" as answer;
                                                         --   SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) AND directionWall=4) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+1) and directionWall=4 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        SELECT log, " взорвал стену справа от себя" as answer;
                                                         --   SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSE -- ЕСЛИ стены справа все таки нет
                                                        SELECT log, " пытался взорвать стену, но там ее нет" as answer;
                                                    end IF;
                                            
                                            WHEN 3
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            SELECT log, " пытался взорвать стену, но она внешняя" as answer;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) and directionWall=1 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        SELECT log, " взорвал стену снизу от себя" as answer;
                                                            -- SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)+5) and directionWall=1 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        SELECT log, " взорвал стену снизу от себя" as answer;
                                                         --   SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSE -- ЕСЛИ стены снизу все таки нет
                                                        SELECT log, " пытался взорвать стену, но там ее нет" as answer;
                                                    end IF;

                                            WHEN 4
                                                THEN
                                                    IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=(SELECT place FROM players WHERE login=log) AND directionWall=direction) -- проверяем не внешняя ли стена
                                                        THEN
                                                            SELECT log, " пытался взорвать стену, но она внешняя" as answer;

                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(SELECT place FROM players WHERE login=log)   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                        THEN
                                                            UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) and directionWall=2 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        SELECT log, " взорвал стену слева от себя" as answer;
                                                            -- SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                        THEN
                                                        UPDATE players SET grenade=grenade-1 WHERE login=log; -- уменьшаем кол-во цемента у игрока
                                                        DELETE FROM walls WHERE wall=(SELECT place FROM players WHERE login=log) and directionWall=direction AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        DELETE FROM walls WHERE wall=((SELECT place FROM players WHERE login=log)-1) and directionWall=2 AND game_id=id; -- удаляем нашу стену из общего списка стен
                                                        SELECT log, " взорвал стену слева от себя" as answer;
                                                        --    SELECT log, " пытался взорвать стену, но там ее нет";
                                                    ELSE -- ЕСЛИ стены сверху все таки нет
                                                         SELECT log, " пытался взорвать стену, но там ее нет" as answer;

                                                    end IF;
                                        END CASE;

                                     END IF;       
                                END IF;
                        ELSE 
                            SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                        END IF;
      
                ELSE 
                    SELECT "error", "Упссс! Кажется, сейчас не твой ход!" as err;
                END IF; 

        ELSE 
             SELECT "error Куда идешь? Ты не в игре." as err;
        END IF;               
        
ELSE
	SELECT "error", "wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;

CALL movePlayer("1","1", 1);
CALL shoot("1","1", 1);

-- стрельба 
/* НЕ РАБОТАЕТ:
уменьшается жизнь у стреляющего, а не у раненых
клад не удаляется у игрокаигрок не перемещается на место убитого
проблема в WHERE game_id=id and place=cell; */

DELIMITER //
CREATE  PROCEDURE shoot( log VARCHAR(30), pw VARCHAR(50), direction INT)
BEGIN 
DECLARE id INT DEFAULT (SELECT game_id FROM players WHERE login=log); -- запоминаем id игры
DECLARE cell INT DEFAULT (SELECT place FROM players WHERE login=log); -- запоминаем расположение игрока

IF EXISTS (SELECT * FROM players WHERE login=log and password=pw) -- если такой игрок есть
    THEN 
        IF (SELECT game_id FROM players WHERE login=log and password=pw) IS NOT NULL -- если игрок находится в игре
            THEN          
                IF EXISTS (SELECT * FROM moves WHERE login=log) -- смотрим наш ход сейчас или нет
                    THEN
                        IF (SELECT lives FROM players WHERE login=log)>0 -- остались ли жизни или нет
                            THEN
                                IF (SELECT place FROM players WHERE login=log)=(SELECT arsenal FROM game WHERE game_id=id) -- находимся ли мы в арсенале или нет
                                    THEN
                                        SELECT log, " пытался стрелять, но из арсенала нельзя стрелять" as answer;
                                ELSE

                                    IF (SELECT patron FROM players WHERE login=log)=0 -- есть ли цемент или нет
                                    THEN
                                        SELECT log, " пытался стрелять, но нет патронов" as answer;
                                ELSE
                                     
                                        CASE direction
                                            WHEN 1    
                                                THEN
                                                   REPEAT
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                               SELECT log, " стрелял вверх и ни в кого не попал1" as answer;
                                                               SET cell=0;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                                SELECT log, " стрелял вверх и ни в кого не попал2" as answer;
                                                                SET cell=0;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell-5) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                                 SELECT log, " стрелял вверх и ни в кого не попал3" as answer;
                                                                 SET cell=0;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=cell-- стоит ли на клетке выше игрок
                                                                THEN
                                                                    UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=NULL WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=1 WHERE login=log; -- помещаем клад себе
                                                                            SELECT log, " попал в игрока сверху от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer;
                                                                    ELSE                                                                        
                                                                        SELECT log, " попал в игрока сверху от себя, отобрал его запасы и заполнил свои"  as answer;
                                                                    END IF; 
                                                                    /* ВСТАВИТЬ ЧТО-ТО ПРО 4 ВНЕОЧЕРЕДНЫХ ХОДА */
                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    SET cell=0;                                                                    
                                                            ELSE 
                                                                SET cell=cell-5; -- идем еще на одну клетку наверх

                                                                IF (cell <5 )
                                                                    THEN
                                                                        SELECT log, " стрелял вверх и ни в кого не попал4" as answer;
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                    UNTIL cell <5 
                                                    END REPEAT;

                                                    /* SELECT log, " стрелял вверх и ни в кого не попал4" as answer; */
                                                    /* UPDATE players SET patron=patron-1  WHERE login=log; */

                                            WHEN 2
                                                THEN
                                                    REPEAT 
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                               SELECT log, " стрелял вправо и ни в кого не попал1" as answer;
                                                               SET cell=5;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                                SELECT log, " стрелял вправо и ни в кого не попал2" as answer;
                                                                SET cell=5;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell+1) AND directionWall=3) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                                 SELECT log, " стрелял вправо и ни в кого не попал3" as answer;
                                                                 SET cell=5;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=(cell)-- стоит ли на клетке правее игрок
                                                                THEN
                                                                   UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=false WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=true WHERE login=log; -- помещаем клад себе
                                                                            SELECT log, " попал в игрока вправа от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer;
                                                                    ELSE                                                                        
                                                                        SELECT log, " попал в игрока вправа от себя, отобрал его запасы и заполнил свои"  as answer;
                                                                    END IF; 

                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    SET cell=5;  
                                                                    SELECT " in to IF", cell ;                                                                  
                                                            ELSE 
                                                                SET cell=cell+1; -- идем еще на одну клетку вправо

                                                                IF (cell=5 OR cell=10 OR cell=15 OR cell=20 OR cell=25)
                                                                    THEN
                                                                        SELECT log, " стрелял вправо и ни в кого не попал4" as answer;
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                        SELECT cell;
                                                    UNTIL (cell=5 OR cell=10 OR cell=15 OR cell=20 OR cell=25) 
                                                    END REPEAT;

                                                    /* SELECT log, " стрелял вправо и ни в кого не попал1" as answer; */
                                                    
                                            
                                            WHEN 3
                                                THEN
                                                    REPEAT 
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                               SELECT log, " стрелял вниз и ни в кого не попал1" as answer;
                                                               SET cell=30;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                                SELECT log, " стрелял вниз и ни в кого не попал2" as answer;
                                                                SET cell=30;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell+5) AND directionWall=1) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                                 SELECT log, " стрелял вниз и ни в кого не попал3" as answer;
                                                                 SET cell=30;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=cell-- стоит ли на клетке ниже игрок
                                                                THEN
                                                                    UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=false WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=true WHERE login=log; -- помещаем клад себе
                                                                            SELECT log, " попал в игрока снизу от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer;
                                                                    ELSE                                                                        
                                                                        SELECT log, " попал в игрока снизу от себя, отобрал его запасы и заполнил свои"  as answer;
                                                                    END IF; 

                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    SET cell=30;                                                                    
                                                            ELSE 
                                                                SET cell=cell+5; -- идем еще на одну клетку наверх

                                                                IF (cell>21)
                                                                    THEN
                                                                        SELECT log, " стрелял вниз и ни в кого не попал4" as answer;
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                        SELECT cell;
                                                    UNTIL cell>21
                                                    END REPEAT; 

                                                    /* SELECT log, " стрелял вниз и ни в кого не попал1" as answer; */
                                                    
                                            WHEN 4
                                                THEN
                                                    REPEAT 
                                                        IF EXISTS (SELECT directionWall FROM externalwalls WHERE wall=cell AND directionWall=direction) -- проверяем не внешняяли стена
                                                           THEN
                                                               SELECT log, " стрелял влево и ни в кого не попал1" as answer;
                                                               SET cell=1;
                                                               UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон

                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=cell   AND directionWall=direction) -- смотрим есть ли стена там, куда мы хотим пойти
                                                            THEN
                                                                SELECT log, " стрелял влево и ни в кого не попал2" as answer;
                                                                SET cell=1;
                                                                UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSEIF EXISTS (SELECT directionWall FROM walls WHERE wall=(cell-1) AND directionWall=2) -- ЕСЛИ ЕСТЬ НИжНЯЯ СТЕНА У ВЕРхНЕЙ КЛЕТКИ
                                                            THEN
                                                                 SELECT log, " стрелял влево и ни в кого не попал3" as answer;
                                                                 SET cell=1;
                                                                 UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                        ELSE -- ЕСЛИ сейчас на просматриваеммой клетке нет в нашем направлении стен
                                                            IF (SELECT place FROM players where game_id=id limit 1)=cell-- стоит ли на клетке выше игрок
                                                                THEN
                                                                    UPDATE players SET cement=0, patron=0, grenade=0, lives=lives-1 WHERE game_id=id and place=cell; -- отбираем у игроков все их запасы
                                                                    UPDATE players SET cement=3, patron=3, grenade=3 WHERE login=log; -- пополняем свои запасы до максимума                                                                    

                                                                    IF EXISTS (SELECT haveTreasure FROM players where game_id=id and place=cell) -- если у убитых есть клад
                                                                        THEN
                                                                            UPDATE players SET haveTreasure=false WHERE game_id=id and place=cell; -- удаляем клад у них
                                                                            UPDATE players SET haveTreasure=true WHERE login=log; -- помещаем клад себе
                                                                            SELECT log, " попал в игрока слева от себя, отобрал его запасы, заполнил свои и забрал КЛАД"  as answer;
                                                                    ELSE                                                                        
                                                                        SELECT log, " попал в игрока слева от себя, отобрал его запасы и заполнил свои"  as answer;
                                                                    END IF; 

                                                                    UPDATE players SET place=cell WHERE login=log; -- перемещаемся на место убитого игрока
                                                                    SET cell=1;
                                                                    SELECT " in to IF", cell ;                                                                     
                                                            ELSE 
                                                                SET cell=cell-1; -- идем еще на одну клетку наверх

                                                                IF (cell=1 OR cell=6 OR cell=11 OR cell=16 OR cell=21)
                                                                    THEN
                                                                        SELECT log, " стрелял влево и ни в кого не попал4" as answer;
                                                                        UPDATE players SET patron=patron-1 WHERE login=log;-- убираем один израсходованный патрон
                                                                END IF;
                                                            END IF;
                                                        END IF;
                                                        SELECT cell;
                                                    UNTIL (cell=1 OR cell=6 OR cell=11 OR cell=16 OR cell=21)
                                                    END REPEAT; 

                                                    /* SELECT log, " стрелял влево и ни в кого не попал1" as answer; */
                                        END CASE;

                                     END IF;       
                                END IF; 
                        ELSE 
                            SELECT "error у тебя не осталось жизней! Ты проиграл." as err;
                        END IF;
      
                ELSE 
                    SELECT "error", "Упссс! Кажется, сейчас не твой ход!" as err;
                END IF; 

        ELSE 
             SELECT "error Куда идешь? Ты не в игре." as err;
        END IF;               
        
ELSE
	SELECT "error", "wrong log or pw" as err;            
END IF;
            
END //
DELIMITER ;

CALL movePlayer("1","1", 1);
>>>>>>> ab046d127beefb5a022e932174a6f3441abf78f0
CALL shoot("1","1", 1);