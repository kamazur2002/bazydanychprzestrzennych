-- Zadanie 1: Analiza zmian w budynkach
CREATE TEMP TABLE buildings_change_analysis AS
SELECT 
    b2018.polygon_id AS old_building_id,
    b2019.polygon_id AS new_building_id,
    b2018.geom AS old_geom,
    b2019.geom AS new_geom
FROM t2018_kar_buildings b2018
RIGHT JOIN t2019_kar_buildings b2019 ON b2018.polygon_id = b2019.polygon_id
WHERE b2018.polygon_id IS NULL -- Nowe budynki 
UNION ALL -- połączenie tego razem
SELECT 
    b2018.polygon_id AS old_building_id,
    b2019.polygon_id AS new_building_id,
    b2018.geom AS old_geom,
    b2019.geom AS new_geom
FROM t2018_kar_buildings b2018
RIGHT JOIN t2019_kar_buildings b2019 ON b2018.polygon_id = b2019.polygon_id
WHERE (NOT ST_Equals(b2019.geom, b2018.geom)) -- Zmiany geometrii
       OR b2019.height <> b2018.height; -- Zmiany wysokości

-- Zadanie 2: Identyfikacja nowych punktów zainteresowania
WITH poi_buffer AS (
    SELECT ST_Buffer(new_geom, 0.005) AS buffered_geom
    FROM buildings_change_analysis
), -- bufor 500m wokol budynkow
new_points_of_interest AS (
    SELECT 
        p2018.poi_id AS old_poi_id,
        p2019.poi_id AS new_poi_id,
        p2019.geom AS new_geom,
        p2019.type AS poi_type 
    FROM t2018_kar_poi_table p2018
    RIGHT JOIN t2019_kar_poi_table p2019 ON p2018.poi_id = p2019.poi_id
    WHERE p2018.poi_id IS NULL -- Nowe punkty 
),
poi_count AS (
    SELECT SUM(CASE WHEN ST_intersects(b.buffered_geom, p.new_geom) THEN 1 ELSE 0 END) AS total_poi, p.poi_type 
    FROM new_points_of_interest p
    CROSS JOIN poi_buffer b
    GROUP BY p.poi_type
) -- poi które wchodzą w bufor
SELECT *
FROM poi_count
WHERE total_poi <> 0; -- Liczymy tylko typy z punktami

-- Zadanie 3: Reprojekcja ulic
CREATE TABLE reprojected_streets AS
SELECT 
    gid, 
    link_id, 
    st_name AS street_name,
    ref_in_id, 
    nref_in_id, 
    func_class, 
    speed_cat, 
    fr_speed_l, 
    to_speed_l,
    dir_travel, 
    ST_SetSRID(geom, 3068) AS geometry -- odpowiedni SRID
FROM t2019_kar_streets;

SELECT * FROM reprojected_streets;

-- Zadanie 4: Tworzenie tabeli dla punktów wejściowych
CREATE TABLE input_coordinates (
    coordinate_id INT,
    coordinate_geom GEOMETRY
);

INSERT INTO input_coordinates (coordinate_id, coordinate_geom)
VALUES (1, 'POINT(8.36093 49.03174)'),
       (2, 'POINT(8.39876 49.00644)');

-- Zadanie 5: Ustawienie SRID dla punktów wejściowych
UPDATE input_coordinates
SET coordinate_geom = ST_SetSRID(coordinate_geom, 3068);

-- Zadanie 6: Wyszukiwanie węzłów ulic przecinających się z punktami
WITH reprojected_nodes AS (
    SELECT 
        gid, 
        node_id, 
        link_id, 
        point_num, 
        z_level, 
        "intersect",
        lat, 
        lon, 
        ST_SetSRID(geom, 3068) AS geom -- repojekcja
    FROM t2019_kar_street_node
), point_buffer AS (
    SELECT ST_Buffer(ST_MakeLine(coordinate_geom), 0.002) AS geometry -- bufor dla punktów
    FROM input_coordinates 
)
SELECT *
FROM reprojected_nodes AS s 
CROSS JOIN point_buffer AS b 
WHERE ST_intersects(b.geometry, s.geom); -- przeciecia

-- Zadanie 7: Liczenie sklepów sportowych w parkach
WITH park_buffer AS (
    SELECT ST_Buffer(geom, 0.003) AS geometry 
    FROM t2019_kar_land_use_a
    WHERE type = 'Park (City/County)' -- Tylko parki
), sporting_goods_store AS (
    SELECT * 
    FROM t2019_kar_poi_table
    WHERE type = 'Sporting Goods Store' -- Tylko sklepy sportowe
)
SELECT COUNT(*)
FROM park_buffer AS b 
CROSS JOIN sporting_goods_store AS s 
WHERE ST_intersects(b.geometry, s.geom);

-- Zadanie 8: Tworzenie tabeli mostów
CREATE TABLE railway_water_crossings AS
SELECT ST_intersection(r.geom, w.geom) 
FROM t2019_kar_railways r 
INNER JOIN t2019_kar_water_lines w ON ST_intersects(r.geom, w.geom); --  przecięcia
