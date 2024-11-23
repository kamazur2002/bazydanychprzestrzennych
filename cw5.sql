-- zadanie 1

CREATE TABLE objects (
	id SERIAL PRIMARY KEY,
	geometry geometry,
	name text
);

-- obiekt 1
INSERT INTO objects("name", geometry) 
VALUES
('obiekt1', ST_Collect(
				ARRAY[(ST_GeomFromText('LINESTRING(0 1, 1 1)')),
        			  (ST_CurveToLine(ST_GeomFromText('CIRCULARSTRING(1 1, 2 0, 3 1)'))),
        			  (ST_CurveToLine(ST_GeomFromText('CIRCULARSTRING(3 1, 4 2, 5 1)'))),
        			  (ST_GeomFromText('LINESTRING(5 1, 6 1)'))]
 							
));

-- obiekt 2
INSERT INTO objects("name", geometry) 
VALUES
('obiekt2', 
			ST_Collect(
				ARRAY[
					ST_GeomFromText('LINESTRING(10 6, 14 6)'),
					ST_CurveToLine(ST_GeomFromText('CIRCULARSTRING(14 6, 16 4, 14 2)')),
					ST_CurveToLine(ST_GeomFromText('CIRCULARSTRING(14 2, 12 0, 10 2)')),
					ST_GeomFromText('LINESTRING(10 2, 10 6)'),
					ST_Buffer(ST_POINT(12, 2), 1)
				]
));	

-- obiekt 3
INSERT INTO objects("name", geometry) 
VALUES
('obiekt3', 
			'Polygon((7 15,10 17, 12 13, 7 15))'
);

-- obiekt 4
INSERT INTO objects("name", geometry) 
VALUES
('obiekt4', 
			'LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'
);

-- obiekt 5
INSERT INTO objects("name", geometry) 
VALUES
('obiekt5', ST_Collect(
			'POINT(30 30 59)',
			'POINT(38 32 234)'
));

-- obiekt 6
INSERT INTO objects("name", geometry) 
VALUES
('obiekt6', ST_Collect(
			'LINESTRING(1 1, 3 2)',
			'POINT(4 2)'
));

-- 2.
-- Obliczenie pola bufora wokół najkrótszej linii między obiektami 'obiekt3' i 'obiekt4'
SELECT ST_Area(
    ST_Buffer(
        ST_ShortestLine(o3.geometry, o4.geometry), 
        5
    )
)
FROM objects o3
CROSS JOIN objects o4
WHERE o3.name = 'obiekt3' AND o4.name = 'obiekt4';

-- 3.
-- Pierwszy i ostatni punkt muszą być takie same
UPDATE objects
SET geometry = ST_MakePolygon(ST_AddPoint(geometry, 'POINT(20 20)'))
WHERE "name" = 'obiekt4';

-- 4.
-- Tworzenie obiektu 'obiekt7' jako kolekcji geometrii 'obiekt3' i 'obiekt4'
INSERT INTO objects ("name", geometry)
VALUES (
    'obiekt7',
    ST_Collect(
        (SELECT geometry FROM objects WHERE "name" = 'obiekt3'),
        (SELECT geometry FROM objects WHERE "name" = 'obiekt4')
    )
);


-- 5.
-- Obliczenie sumy powierzchni buforów (bez łuków) bez użycia CTE
SELECT SUM(ST_Area(ST_Buffer(geometry, 5))) AS total_area
FROM objects
WHERE NOT ST_HasArc(geometry);