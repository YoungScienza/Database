#EX 1 Consider to check which food product are offered at least in two different format (i.e.
#different weights). List all these products, adding to the data identifying the products
#the two different weights.

SELECT f1.name, f1.weight, f2.weight AS w2, f1.unit, f1.price
FROM food f1, food f2
WHERE f1.name = f2.name
AND f1.weight > f2.weight
AND f1.unit = f2.unit
ORDER BY f1.name;

#EX2 Which food products have been mostly consulted?
SELECT f.name, COUNT(*) AS nr
FROM consulted c JOIN food f ON (f.unit = c.food_unit
							AND f.weight = c.food_weight
                            AND f.name = c.food_name)
GROUP BY f.name
HAVING nr >= ALL(SELECT COUNT(food_name)
				FROM consulted
                group by food_name);
                
#EX 3 Report for each offered product, by the online market, how many times they has been
# consulted and selected. Consider a tabular output.

SELECT c.food_name, COUNT(*) AS nr
FROM consulted c JOIN selected s ON (s.food_unit = c.food_unit
							AND s.food_weight = c.food_weight
                            AND s.food_name = c.food_name
                            AND c.ID = s.ID)
GROUP BY c.food_name;

SELECT c.name, c.unit, c.weight ,c.consulted, s.selected
FROM (SELECT name, unit, weight, COUNT(food_name) AS consulted
		FROM food LEFT OUTER JOIN consulted ON (food_unit = food.unit
							AND food_weight = food.weight
                            AND food_name = food.name)
	  GROUP BY name) c,
      (SELECT name, unit, weight, COUNT(food_name) AS selected
		FROM food LEFT OUTER JOIN selected ON (food_unit = food.unit
							AND food_weight = food.weight
                            AND food_name = food.name)
	  GROUP BY name) s
WHERE c.name = s.name
AND c.unit = s.unit
AND c.weight = s.weight
ORDER BY c.name;


#EX4 Consider each access (ID), when it happened (date), and at which time and what
#product the user has consulted. We assume that a consultation follows access time.

SELECT u.ID, u.date, u.time, c.food_name
FROM user u JOIN consulted c ON u.ID = c.ID
WHERE c.time > u.time
ORDER BY u.date DESC;


      