-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Май 10 2021 г., 01:43
-- Версия сервера: 10.4.18-MariaDB
-- Версия PHP: 8.0.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `labirint_game_project`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `connectGame` (IN `log` VARCHAR(30), IN `pw` VARCHAR(50), IN `game_md` VARCHAR(32))  BEGIN 
declare id int default (select game_id from game where md=game_md);

IF EXISTS  (SELECT * from game where md=game_md)
THEN
	if id is not NULL -- если id не ноль (такая игра есть)
		then 
    	IF EXISTS (SELECT * FROM players WHERE login=log AND password=pw) -- если такой игрок существует
	     	THEN 
 			IF (select game_id from players where login=log) is NULL
 				THEN -- если этот игрок не находится в другой игре
 
 				if ((select size from game where game_id=id)>(select count(*) from players where game_id=id)) -- если у нас нет нужного кол-ва игроков
        			THEN    
       START TRANSACTION;
			update players set game_id=id where login=log;
   
     				 IF ((select size from game where game_id=id)=(select count(*) from players where game_id=id))
       					 THEN 
        					CALL createField(id); -- вызываем функцию для создания игрового поля
            				INSERT INTO moves VALUES ((SELECT login from players where game_id=id and indexNumber=(SELECT min(indexNumber) from players where game_id=id)), CURRENT_TIMESTAMP); -- вставляем игрока в таблицу хода, выбираем, кто за ним следует
            SELECT login, COUNT(*) as count FROM players WHERE game_id=id;
            				COMMIT;
       				 else
        				SELECT login, COUNT(*) as count from players WHERE game_id=id;
           				COMMIT;
  					 END IF;
     
				else SELECT "Error! неправильный game_id " ;
        
    			end IF;
      
			else SELECT "Error! у игрока уже есть id игры";
			END IF;
    
    	ELSE SELECT "Error! неправильный логин пароль" ;

   		END IF;
    
    ELSE SELECT "Error!, id игры равен null (connectGame)" ;
    END IF;
    
ELSE SELECT "Error!, такого md игры не существует. Просмотри код еще разок." ;
    END IF;
    
    
        
   end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createField` (IN `id_of_game` INT)  BEGIN 
-- DECLARE g_size INT DEFAULT(SELECT COUNT(*) FROM players WHERE game_id=id_of_game); -- посчитали ручками кол-во игроков, которые есть в игре	
	  
    IF EXISTS (select * from game where game_id=id_of_game)   -- если такая игра есть
    	THEN    
   			
			if (SELECT COUNT(*) FROM players WHERE game_id=id_of_game)=(select size from game where game_id = id_of_game)
              	then
                
              		CREATE TEMPORARY TABLE result (login VARCHAR(30), num int); -- временно храним расположение игроков/баз					
                    CREATE TEMPORARY TABLE tempPlayers (numbs INT PRIMARY KEY AUTO_INCREMENT, login VARCHAR(30)); -- временно храним игроков\базы         
                    CREATE TEMPORARY TABLE tempNnumbers (numbs INT PRIMARY KEY AUTO_INCREMENT, num INT); -- временно храним ячейки
                    INSERT INTO tempNnumbers(num) SELECT n from numbers ORDER BY rand() limit 10; -- вставляем рандомно рандомные числа в таблицу
               
                    INSERT INTO tempPlayers SELECT null, login FROM players WHERE game_id=id_of_game; -- вставляем логины игроков во врем таблицу
                    INSERT INTO tempPlayers(login) VALUES('arsenal'), ('robbers'),('treasure'); -- вставляем нужные предметы в таблицу
               
                    INSERT INTO result select login, num FROM tempNnumbers NATURAL JOIN tempPlayers ; -- распределяем клетки между игроками
                         
                   UPDATE players set place =(SELECT num FROM result WHERE result.login=players.login limit 1) WHERE game_id=id_of_game; -- расставляем местоположение игроков
                   UPDATE game set robbers = (SELECT num FROM result WHERE login="robbers"), 
                   arsenal=(SELECT num FROM result WHERE login="arsenal"), 
                   treasure=(SELECT num FROM result WHERE login="treasure") WHERE game_id=id_of_game; -- добавляем все наши данные в игру
                   
                    UPDATE game set exitCell=(SELECT wall from externalwalls ORDER BY rand() LIMIT 1) WHERE game_id=id_of_game;
                    UPDATE game set directionExit=(SELECT directionWall from externalwalls, game where wall=exitCell limit 1) WHERE game_id=id_of_game;
                    UPDATE players set lives=3, cement=3, patron=3, grenade=3 WHERE game_id=id_of_game;
 
      ELSE SELECT "Error!", "Недостаточное кол-во игроков для создания поля.";
     END IF; 
    
     ELSE 
 	    SELECT "Error!", " Sorry! Что-то сломалось и такого id игры нет!";
      END IF; 
   END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createGame` (IN `log` VARCHAR(30), IN `pw` VARCHAR(50), IN `number` INT, IN `pblc` BOOLEAN)  BEGIN
declare x int default 0;
	IF EXISTS (SELECT * FROM players WHERE login=log AND password=pw)
	     THEN
                  
         START TRANSACTION;
    	INSERT INTO game(game_id, md, size, public, arsenal, robbers, treasure,	exitCell, directionExit, random) VALUES(NULL, NULL, number, pblc, NULL, NULL, NULL, NULL, NULL, rand()*1000000);
       set x= last_insert_id();

 UPDATE game SET md=MD5(game_id) where game_id=x; 
     update players set game_id=x where login=log ;
   COMMIT;
-- update players set inGame=1 where login=log;

 SELECT md from game WHERE game_id=x ;   
       else SELECT "Error! неправильный логин/пароль" ;     
	    end IF;
 
   end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createUser` (IN `log` VARCHAR(30), IN `pw` VARCHAR(50))  BEGIN
        IF (SELECT COUNT(*) FROM players WHERE login=log) = 0 
        THEN
			INSERT INTO players VALUES(
    log, pw, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) ; 
    SELECT "ok" as answer;
		else SELECT "Error! такой логин уже существует, придумай себе другой" as err;
        
     end IF;
   end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `destroyWall` (IN `log` VARCHAR(30), IN `pw` VARCHAR(50), IN `direction` INT)  BEGIN 
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
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `endGame` (IN `g_id` INT, IN `random_num` INT)  BEGIN 

IF random_num=(SELECT random FROM game WHERE game_id=id)
    THEN -- если рандомное число совпадает с тем, что в игре

 DELETE FROM moves WHERE login=log; 
 UPDATE players SET lives=null, cement=null, patron=null, grenade=null, palce=null WHERE game_id=g_id;
 DELETE FROM game WHERE game_id=g_id;
 
 SELECT "Спасибо за игру!" as endgame ;
 
 ELSE SELECT "Данную функцию нельзя вызвать просто так! (endGame)" as err;
 END IF;
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `exitGame` (`log` VARCHAR(30), `pw` VARCHAR(30))  BEGIN
declare g_id int DEFAULT (SELECT game_id from players where login=log);
IF EXISTS (select * from players where login=log and password=pw) -- ЕСЛИ ТАКОЙ ИГРОК СУЩЕСТВУЕТ
	THEN
		IF EXISTS (select * from game where game_id=g_id) -- ЕСЛИ ЕСТЬ ТАКАЯ ИГРА
           THEN
			if ((select size FROM game join players using (game_id) WHERE login=log and game.game_id=players.game_id)=(select count(*) from players where game_id=g_id)) -- проверяем, что кол-во игроков равно тому что в size - игра началась
				THEN
		
				START TRANSACTION;
				UPDATE players SET game_id=NULL, lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log; -- ОбНУЛЯЕМ ИГРОКА
				UPDATE game SET size=size-1 WHERE game_id=g_id; -- меняем кол-во игроков в игре, чтобы все хорошо считалосьъ
 				COMMIT;
				call updateMove(log, (SELECT random from game where game_id=g_id));

			    IF ((select count(*) from players where game_id=g_id)=1) -- если игрок остался один
				    THEN
 
					    START TRANSACTION;
					    DELETE FROM game WHERE game_id=g_id; -- удаляем игру (game_id у игрока удаляется вместе с game_id у игры)
    				    UPDATE players SET lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log;
 					    COMMIT;
       
    		    END IF;
		    else 
			    START TRANSACTION;
			    UPDATE players SET game_id=Null, lives=NULL, cement=NULL, patron=NULL, grenade=NULL WHERE login=log;			    
			    SELECT "Ты вышел из игры, которая не нечалась!";
			    COMMIT;       
		    end if;

	    ELSE
		    SELECT "упс, кажется, такой игры нет!";
	    end if;
ELSE
	SELECT "такого логина или пароля нет! Проверь написание и раскладку!";
end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `logout` (`log` VARCHAR(30), `pw` VARCHAR(50))  BEGIN
	IF (SELECT COUNT(*) FROM players WHERE login=log) = 1 
		THEN
        IF (select game_id from players WHERE login = log)!=NULL -- если игрок находится в игре
			THEN
				DELETE FROM players where login=log AND password=pw;
            else SELECT "Error! Ты находишься в игре. Сначала Выйди из нее и уже выходи из системы." ;     
    end IF;
	else SELECT "Error! Такой логин не существует" ;     
    end IF;
    
   END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `makeWall` (IN `log` VARCHAR(30), IN `pw` VARCHAR(50), IN `direction` INT)  BEGIN 
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
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `movePlayer` (IN `log` VARCHAR(30), IN `pw` VARCHAR(50), IN `direction` INT)  BEGIN 
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
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `shoot` (IN `log` VARCHAR(30), IN `pw` VARCHAR(50), IN `direction` INT)  BEGIN 
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
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPublicGames` ()  BEGIN
	IF EXISTS (select * from game where public=1)     
        THEN
                                                  
            select md, size, (select count(*) from players where game.game_id=players.game_id) as have_players, (select login from players WHERE game_id=game.game_id limit 1) as creator FROM game WHERE public=1 and size>(select count(*) from players where game.game_id=players.game_id) GROUP BY game_id;                       
    ELSE
    SELECT "Sorry! Публичных игр пока нет! Создай свою с помощью createGame() (если ты вошел в систему, иначе войди с помощью createUser())" as err;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateMove` (IN `log` VARCHAR(30), IN `random_num` INT)  BEGIN
declare id int default (SELECT game_id FROM players WHERE login=log);
declare lnext int;

IF random_num=(SELECT random FROM game WHERE game_id=id)
    THEN -- если рандомное число совпадает с тем, что в игре

        if EXISTS ( SELECT indexNumber FROM players WHERE game_id=id AND indexNumber>(SELECT indexNumber FROM players WHERE login=log) LIMIT 1) -- если наш номер не максимальный в игре
            THEN 

                SET lnext=(SELECT indexNumber FROM players WHERE game_id=id and indexNumber>(SELECT indexNumber from players where login=log order by indexNumber) limit 1); 
                           -- в переменную записываем значение
                UPDATE moves SET login = (SELECT login FROM players where indexNumber=lnext), active = CURRENT_TIMESTAMP WHERE login=log; -- меням порядок хода на следующего
                -- UPDATE moves SET active = CURRENT_TIMESTAMP WHERE login=log;
        ELSE -- иначе у нас макс номер игрока и мы должны просто поставить минимального
           
            SET lnext=(SELECT min(indexNumber) FROM players WHERE game_id=id);
            UPDATE moves SET login=(SELECT login FROM players where indexNumber=lnext), active = CURRENT_TIMESTAMP WHERE login=log; -- меням порядок хода на следующего
            -- UPDATE moves SET active = CURRENT_TIMESTAMP WHERE login=log;
        END IF;   
ELSE 
    SELECT "Error, Вы пытаетесь вызвать функцию вне игры, так делать нельзя.(UPDATEmOVE)";
END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `externalwalls`
--

CREATE TABLE `externalwalls` (
  `wall` int(11) NOT NULL,
  `directionWall` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Дамп данных таблицы `externalwalls`
--

INSERT INTO `externalwalls` (`wall`, `directionWall`) VALUES
(1, 4),
(1, 1),
(2, 1),
(3, 1),
(4, 1),
(5, 1),
(5, 2),
(6, 4),
(10, 2),
(11, 4),
(15, 2),
(16, 4),
(20, 2),
(21, 4),
(21, 3),
(22, 3),
(23, 3),
(24, 3),
(25, 3),
(25, 2);

-- --------------------------------------------------------

--
-- Структура таблицы `game`
--

CREATE TABLE `game` (
  `game_id` int(11) NOT NULL,
  `md` varchar(32) DEFAULT NULL,
  `size` int(11) NOT NULL,
  `public` tinyint(1) DEFAULT NULL,
  `arsenal` int(10) UNSIGNED DEFAULT NULL,
  `robbers` int(10) UNSIGNED DEFAULT NULL,
  `treasure` int(10) UNSIGNED DEFAULT NULL,
  `exitCell` int(10) UNSIGNED DEFAULT NULL,
  `directionExit` int(10) UNSIGNED DEFAULT NULL,
  `random` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Дамп данных таблицы `game`
--

INSERT INTO `game` (`game_id`, `md`, `size`, `public`, `arsenal`, `robbers`, `treasure`, `exitCell`, `directionExit`, `random`) VALUES
(1, 'c4ca4238a0b923820dcc509a6f75849b', 3, 1, NULL, NULL, NULL, NULL, NULL, 34),
(3, 'eccbc87e4b5ce2fe28308fd9f2a7baf3', 3, 1, 16, 13, 4, 2, 1, 12),
(4, 'a87ff679a2f3e71d9181a67b7542122c', 3, 0, 10, 22, 9, NULL, NULL, 950240),
(5, 'e4da3b7fbbce2345d7772b0674a318d5', 3, 0, NULL, NULL, NULL, NULL, NULL, 823106),
(6, '1679091c5a880faf6fb5e6087eb1b2dc', 3, 0, NULL, NULL, NULL, NULL, NULL, 293149),
(7, '8f14e45fceea167a5a36dedd4bea2543', 3, 0, NULL, NULL, NULL, NULL, NULL, 556512),
(8, 'c9f0f895fb98ab9159f51fd0297e236d', 3, 0, NULL, NULL, NULL, NULL, NULL, 238715),
(9, '45c48cce2e2d7fbdea1afc51c7c6ad26', 3, 1, NULL, NULL, NULL, NULL, NULL, 426097);

-- --------------------------------------------------------

--
-- Структура таблицы `moves`
--

CREATE TABLE `moves` (
  `login` varchar(30) DEFAULT NULL,
  `active` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Дамп данных таблицы `moves`
--

INSERT INTO `moves` (`login`, `active`) VALUES
('1', '00:25:03'),
('k', '23:13:09');

-- --------------------------------------------------------

--
-- Структура таблицы `numbers`
--

CREATE TABLE `numbers` (
  `n` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Дамп данных таблицы `numbers`
--

INSERT INTO `numbers` (`n`) VALUES
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10),
(11),
(12),
(13),
(14),
(15),
(16),
(17),
(18),
(19),
(20),
(21),
(22),
(23),
(24),
(25);

-- --------------------------------------------------------

--
-- Структура таблицы `players`
--

CREATE TABLE `players` (
  `login` varchar(30) NOT NULL,
  `password` varchar(50) NOT NULL,
  `indexNumber` int(10) UNSIGNED NOT NULL,
  `game_id` int(11) DEFAULT NULL,
  `lives` int(11) DEFAULT NULL,
  `cement` int(11) DEFAULT NULL,
  `patron` int(11) DEFAULT NULL,
  `grenade` int(11) DEFAULT NULL,
  `place` int(11) DEFAULT NULL,
  `haveTreasure` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Дамп данных таблицы `players`
--

INSERT INTO `players` (`login`, `password`, `indexNumber`, `game_id`, `lives`, `cement`, `patron`, `grenade`, `place`, `haveTreasure`) VALUES
('1', '1', 2, 3, 2, 3, 3, 3, 25, 1),
('aa', '1', 19, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('dd', '1', 17, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('f', '1', 5, 3, 2, 1, 0, 0, 4, NULL),
('ff', '1', 16, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('g', '1', 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('h', '1', 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('i', '1', 15, 8, NULL, NULL, NULL, NULL, NULL, NULL),
('j', '1', 8, 5, NULL, NULL, NULL, NULL, NULL, NULL),
('k', '1', 9, 4, 3, 3, 3, 3, 20, NULL),
('l', '1', 10, 4, 3, 3, 3, 3, 11, NULL),
('qq', '1', 20, 4, 3, 3, 3, 3, 24, NULL),
('r', '1', 12, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('ss', '1', 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('t', '1', 11, 9, NULL, NULL, NULL, NULL, NULL, NULL),
('u', '1', 14, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('v', '1', 4, 3, 2, 0, 2, 0, 4, 1),
('vika', '1', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('x', '1', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('y', '1', 13, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Структура таблицы `walls`
--

CREATE TABLE `walls` (
  `wall` int(11) DEFAULT NULL,
  `directionWall` int(11) DEFAULT NULL,
  `game_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `game`
--
ALTER TABLE `game`
  ADD PRIMARY KEY (`game_id`),
  ADD UNIQUE KEY `md` (`md`);

--
-- Индексы таблицы `moves`
--
ALTER TABLE `moves`
  ADD UNIQUE KEY `login` (`login`);

--
-- Индексы таблицы `numbers`
--
ALTER TABLE `numbers`
  ADD PRIMARY KEY (`n`);

--
-- Индексы таблицы `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`login`),
  ADD UNIQUE KEY `loginNext` (`indexNumber`),
  ADD KEY `game_id` (`game_id`);

--
-- Индексы таблицы `walls`
--
ALTER TABLE `walls`
  ADD KEY `game_id` (`game_id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `game`
--
ALTER TABLE `game`
  MODIFY `game_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT для таблицы `players`
--
ALTER TABLE `players`
  MODIFY `indexNumber` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `moves`
--
ALTER TABLE `moves`
  ADD CONSTRAINT `moves_ibfk_1` FOREIGN KEY (`login`) REFERENCES `players` (`login`);

--
-- Ограничения внешнего ключа таблицы `players`
--
ALTER TABLE `players`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `game` (`game_id`) ON DELETE SET NULL;

--
-- Ограничения внешнего ключа таблицы `walls`
--
ALTER TABLE `walls`
  ADD CONSTRAINT `walls_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `game` (`game_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
