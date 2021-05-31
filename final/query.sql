--PREAMBLE--

create view city_flights as (
    select f.flightid, a1.city as origin, a2.city as dest, (f.departuredelay + f.arrivaldelay) delay from flights f, airports a1, airports a2
    where a1.airportid = f.originairportid and a2.airportid = f.destairportid
);

create view flights_city as (select q1.source, q1.dest, q1.source_state, q1.dest_state, sum(arrivaldelay)+sum(departuredelay) as total_delay from 
(select a1.city as source, a2.city as dest, a1.state source_state, a2.state dest_state, f.arrivaldelay, f.departuredelay from airports a1, airports a2, flights f 
where a1.airportid = f.originairportid and a2.airportid = f.destairportid) as q1 
group by q1.source, q1.dest, q1.source_state, q1.dest_state );


create view Ny_city as (select a1.city from airports a1 where a1.state = 'New York');

create view days as (with recursive res(n) as (select 1 as n union select n+1 from res where n<31) select * from res);

create view authoredge as(
    select a1.authorid author1, a2.authorid author2, a1.paperid from authorpaperlist a1, authorpaperlist a2 where a1.paperid = a2.paperid and a1.authorid <> a2.authorid
);

create view authorpath as (
    with recursive path(author1, author2, intermediate) as (
        select author1, author2, Array[author1, author2] from authoredge
        union
        select p.author1, a.author2, p.intermediate || a.author2 from path p, authoredge a where p.author2 = a.author1 and a.author2 <> all(p.intermediate)
    )
    select * from path
);

create view citationpath as (

    with recursive path(paperid1, paperid2, intermediate) as 
    (select paperid1, paperid2, array[paperid1, paperid2] from citationlist
    union
    select p.paperid1, cl.paperid2, p.intermediate || cl.paperid2 from path p, citationlist cl 
    where p.paperid2 = cl.paperid1 and cl.paperid2 <> all(p.intermediate)
    )select * from path
);

create view authorpath3 as(select q1.author1, q1.author2, q1.length from (select author1, author2, (array_length(ap.intermediate, 1)-1) as length, 
row_number() over (partition by ap.author1, ap.author2 order by array_length(ap.intermediate,1)) as rk
from authorpath ap ) as q1 where q1.rk = 1 and q1.length = 3);

create view coauthorlist as (with recursive coauthor as (
    select apl.paperid, Array[apl.authorid] as authors from authorpaperlist apl
    union
    select co.paperid, authors || apl.authorid from authorpaperlist apl, coauthor co where co.paperid = apl.paperid and apl.authorid <> all(co.authors)
)select * from coauthor);



--1--
with recursive path(originairportid, destairportid, carrier) as 
(select originairportid, destairportid, carrier from flights where originairportid = 10140 
union select path.originairportid, flights.destairportid, flights.carrier from path, flights where 
path.destairportid = flights.originairportid and path.carrier = flights.carrier)
select distinct airports.city as name from path, airports where path.destairportid = airports.airportid order by city;


--2--

with recursive path(originairportid, destairportid, dayofweek) as 
(select originairportid, destairportid, dayofweek from flights where originairportid = 10140 
union select path.originairportid, flights.destairportid, flights.dayofweek from path, flights where 
path.destairportid = flights.originairportid and path.dayofweek = flights.dayofweek)
select distinct airports.city as name from path, airports where path.destairportid = airports.airportid order by city;

--3--


with recursive path(originairportid, destairportid, intermediate) as (
    select originairportid, destairportid,Array[originairportid, destairportid] from 
    flights where originairportid = 10140
    union 
    select p.originairportid, f.destairportid, p.intermediate || f.destairportid from 
    path p, flights f where f.originairportid = p.destairportid and f.destairportid <> all(p.intermediate)
)
select a.city as name from path p, airports a where p.destairportid = a.airportid group by a.city having count(*) = 1 order by name;

--4--

with recursive path(originairportid, destairportid, intermediate) as (
    select originairportid, destairportid,Array[originairportid, destairportid] from 
    flights
    union 
    select p.originairportid, f.destairportid, p.intermediate || f.destairportid from 
    path p, flights f where p.originairportid <> p.destairportid and f.originairportid = p.destairportid and 
    (f.destairportid <> all(p.intermediate) or f.destairportid = p.originairportid))
select coalesce((select (max(array_length(p.intermediate, 1))-1) as length from path p where 10140 = any(p.intermediate) and p.originairportid = p.destairportid), 0) as length;

--5--

with recursive path(originairportid, destairportid, intermediate) as (
    select originairportid, destairportid,Array[originairportid, destairportid] from 
    flights
    union 
    select p.originairportid, f.destairportid, p.intermediate || f.destairportid from 
    path p, flights f where p.originairportid <> p.destairportid and f.originairportid = p.destairportid and 
    (f.destairportid <> all(p.intermediate) or f.destairportid = p.originairportid))
select coalesce((select (max(array_length(p.intermediate, 1))-1) as length from path p where p.originairportid = p.destairportid), 0) as length;

--6--

with recursive path(source, dest, dest_state, intermediate) as (
    select source, dest, dest_state, Array[source, dest] from 
    flights_city where source = 'Albuquerque' and source_state<>dest_state
    union 
    select p.source, f.dest, f.dest_state, p.intermediate || f.dest from 
    path p, flights_city f where f.source = p.dest and f.dest <> all(p.intermediate) and p.dest_state <> f.dest_state
)
select count(*) from path p where p.dest = 'Chicago';

--7--

with recursive path(source, dest, dest_state, intermediate) as (
    select source, dest, dest_state, Array[source, dest] from 
    flights_city where source = 'Albuquerque' and source_state<>dest_state
    union 
    select p.source, f.dest, f.dest_state, p.intermediate || f.dest from 
    path p, flights_city f where f.source = p.dest and f.dest <> all(p.intermediate) 
)
select count(*) from path p where p.dest = 'Chicago' and 'Washington' = any(p.intermediate) ;

--8--

with recursive flights_path as(
    select fc.source name1, fc.dest name2, Array[source, dest] as intermediate from flights_city fc
    union
    select fp.name1, fc.dest, intermediate || fc.dest from flights_city fc, flights_path fp 
    where fc.source = fp.name2 and fc.dest <> all(fp.intermediate)

)
select q2.name1, q2.name2 from (select q1.name1, q1.name2 from (select a1.city name1, a2.city name2 from airports a1, airports a2 where a1.city <> a2.city )as q1
except (select name1, name2 from flights_path group by name1, name2)) as q2 order by q2.name1, q2.name2;

--9--

with res as (select q3.day1, coalesce(q2.sum, 0) from ((select n as day1 from days) as q3 left join	
(select q1.dayofmonth as day, sum(totaldelay) from (select f.dayofmonth, f.departuredelay+f.arrivaldelay as totaldelay 
from flights f, airports a where f.originairportid = a.airportid and a.city = 'Albuquerque') as q1 group by q1.dayofmonth) as q2
on q3.day1 = q2.day)
order by sum, day)
select res.day1 as day from res;

--10--

select q1.source as name from 
(select * from flights_city cf where cf.source = any(select * from Ny_city) and cf.dest = any(select * from Ny_city)) as q1
group by q1.source having count(*) = (select count(*) from Ny_city) - 1 order by name; 


--11--

with recursive path as (
    select cf.origin, cf.dest, cf.delay, Array[cf.origin, cf.dest] as intermediate from city_flights cf
    union
    select p.origin, cf.dest, cf.delay, p.intermediate || cf.dest from path p, city_flights cf where p.origin <> p.dest and
    p.dest = cf.origin and cf.delay >= p.delay and (cf.dest = p.origin or cf.dest <> all(p.intermediate))
)
select p.origin as name1, p.dest as name2 from path p group by p.origin, p.dest order by name1, name2;


--12--

with res as (select q2.authorid, q2.length from 
(select q1.author2 as authorid, (q1.length-1) as length,  row_number() over (partition by q1.author2 order by q1.length) as rk
from (select author1, author2, intermediate, Array_length(intermediate,1) length from authorpath ap where ap.author1 = 1235) as q1) as q2
where q2.rk = 1 
union 
select ad.authorid as authorid, -1 as length from authordetails ad where ad.authorid <> 1235 )
select q1.authorid, q1.length from 
(select res.authorid, res.length, row_number() over(partition by authorid order by length desc) as rk from res) as q1
where q1.rk = 1 order by length desc, authorid;


--13--

with recursive path (author2, age, gender, intermediate) as (
select author2, age, gender, Array[author1, author2] as intermediate from authoredge ae, authordetails ad 
where ae.author2 = ad.authorid and ae.author1 = 1558  group by author2, age, gender, intermediate
union
select ae.author2, ad.age, ad.gender, p.intermediate || ae.author2 from path p, authoredge ae, authordetails ad
where p.author2 <> 2826 and p.author2 = ae.author1 and ae.author2 <> all(p.intermediate) and ae.author2 = ad.authorid 
and (ae.author2 = 2826 or (ad.age >35 and ad.gender <> p.gender))
),
res as (
select -1 as count where not exists (select * from authorpath ap where ap.author1 = 1558 and ap.author2 = 2826)
union 
select q1.count from (select count(*) from path p where p.author2 = 2826) as q1 where exists (select * from path p1 where p1.author2 = 2826) 
union
select 0 as count where not exists (select * from path p1 where p1.author2 = 2826) and exists (select * from authorpath ap where ap.author1 = 1558 and ap.author2 = 2826)
)
select count from res ;

--14--

with recursive papercited as (select distinct paperid1 from citationpath cp where cp.paperid2 = 126),
authorcitedpath(author1, author2, paperid, intermediate, c) as (
    select ae.author1, ae.author2, ap.paperid, Array[author1, author2] as intermediate, case
    when ae.author2 = 102 then 1
    when ap.paperid = any(select * from papercited) then 1
    else 0 
    end as c from authoredge ae, authorpaperlist ap where ae.author1 = 704 and ae.author2 = ap.authorid
    union 
    select acp.author1, ae.author2, ap.paperid, acp.intermediate || ae.author2, case 
        when acp.c = 1 then 1
        when acp.c = 0 and ae.author2 <> 102 and ap.paperid = any(select * from papercited) then 1
        else 0
    end as c from authorcitedpath acp, authoredge ae, authorpaperlist ap 
    where acp.author2 = ae.author1 and ae.author2 <> all(acp.intermediate) and ap.authorid = ae.author2
),
res as (
    select -1 as count where not exists (select * from authorpath ap where ap.author1 = 704 and ap.author2 = 102)
    union
    select q2.count from (select count(*) from (select distinct intermediate from authorcitedpath where author2 = 102 and c=1) as q1) as q2 where exists (select distinct intermediate from authorcitedpath where author2 = 102 and c=1)
    union
    select 0 as count where not exists(select distinct intermediate from authorcitedpath where author2 = 102 and c=1) and exists (select * from authorpath ap where ap.author1 = 704 and ap.author2 = 102))
select count from res;

--15--


--16--

select q2.authorid from (select q1.authorid, apl.authorid as authorid2 from (select apl.authorid, cp.paperid2 from authorpaperlist apl, citationpath cp 
where apl.paperid = cp.paperid1 group by authorid, paperid2) as q1, authorpaperlist apl 
where apl.paperid = q1.paperid2 and Array[q1.authorid, apl.authorid] <> all(select authors from coauthorlist) group by q1.authorid, apl.authorid) as q2
group by q2.authorid order by count(*) desc, authorid limit 10;

--17--

with authorcitationcount as (select q3.authorid, sum(count) from (select apl.authorid, apl.paperid, q2.count from (select q1.paperid2, count(*) from 
(select paperid1, paperid2 from citationpath group by paperid1, paperid2) as q1 group by q1.paperid2) as q2, authorpaperlist apl
where apl.paperid = q2.paperid2) as q3 group by q3.authorid) 
select p1.author1 as authorid from(select ap3.author1, sum(acc.sum) from authorcitationcount acc, authorpath3 ap3 
where ap3.author2 = acc.authorid group by ap3.author1) as p1 order by p1.sum desc, p1.author1 limit 10;


--18--

with path as (
    select * from(select * from authorpath ap where author1 = 3552 and author2 = 321) as q1 where 1436 = any(q1.intermediate)
    or 562 = any(q1.intermediate) or 921 = any(q1.intermediate) group by author1, author2, intermediate 
),
res as (
select -1 as count where not exists (select * from authorpath ap where ap.author1 = 3552 and ap.author2 = 321)
union 
select q1.count from (select count(*) from path p ) as q1 where exists (select * from path p1 ) 
union
select 0 as count where not exists (select * from path p1 ) and exists (select * from authorpath ap where ap.author1 = 3552 and ap.author2 = 321)
)
select count from res ;

--19--

--20--

--21--

with recursive confedge as (select author1, author2, conferencename from authoredge ae, paperdetails pd where ae.paperid = pd.paperid),
confpath as (
    select author1, author2, conferencename, Array[author1, author2] as intermediate from confedge
    union
    select cf.author1, ce.author2, ce.conferencename, cf.intermediate || ce.author2 from confedge ce, confpath cf where
    cf.author2 = ce.author1 and cf.conferencename = ce.conferencename and ce.author2 <> all(cf.intermediate)
)
select q4.conferencename, count(*) from (select q3.conferencename, (with sorted as (select unnest(q3.elements) as vals order by vals) select array_agg(vals) 
as sort from sorted) from (select (q2.author1 || q2.elements) as elements, conferencename from 
(select author1, Array_agg(author2) as elements, conferencename from (select author1, author2, conferencename from confpath 
group by author1, author2, conferencename order by conferencename, author1, author2) as q1 group by author1, conferencename)
q2) as q3 group by sort, conferencename) q4 group by conferencename order by count desc, conferencename
;

--22--


with recursive confedge as (select author1, author2, conferencename from authoredge ae, paperdetails pd where ae.paperid = pd.paperid),
confpath as (
    select author1, author2, conferencename, Array[author1, author2] as intermediate from confedge
    union
    select cf.author1, ce.author2, ce.conferencename, cf.intermediate || ce.author2 from confedge ce, confpath cf where
    cf.author2 = ce.author1 and cf.conferencename = ce.conferencename and ce.author2 <> all(cf.intermediate)
)
select q4.conferencename, array_length(q4.sort, 1) as count from (select q3.conferencename, (with sorted as (select unnest(q3.elements) as vals order by vals) select array_agg(vals) 
as sort from sorted) from (select (q2.author1 || q2.elements) as elements, conferencename from 
(select author1, Array_agg(author2) as elements, conferencename from (select author1, author2, conferencename from confpath 
group by author1, author2, conferencename order by conferencename, author1, author2) as q1 group by author1, conferencename)
q2) as q3 group by sort, conferencename) q4  order by count , conferencename
;


--CLEANUP--
drop view flights_city, city_flights, ny_city, days, authoredge, authorpath, citationpath, authorpath3, coauthorlist cascade;






