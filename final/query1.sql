create table authordetails(
    authorid integer,
    authorname text,
    city text,
    gender text,
    age integer,
    constraint authory_key primary key(authorid)
);

create table paperdetails(
    paperid integer,
    papername text,
    conferencename text,
    score integer,
    constraint paper_key primary key(paperid)
);

create table authorpaperlist(
    authorid integer,
    paperid integer,
    constraint authorpaper_key primary key(authorid, paperid),
    constraint author_ref foreign key(authorid) references authordetails(authorid),
    constraint paper_ref foreign key(paperid) references paperdetails(paperid)

);


create table citationlist(
    paperid1 integer,
    paperid2 integer,
    constraint citation_key primary key(paperid1, paperid2),
    constraint paperid1_ref foreign key(paperid1) references paperdetails(paperid),
    constraint paperid2_ref foreign key(paperid2) references paperdetails(paperid)

);

\copy authordetails from '/home/sanjeev/Desktop/airport_data/authors/authordetails.csv' delimiter ',' csv header;
\copy paperdetails from '/home/sanjeev/Desktop/airport_data/authors/paperdetails.csv' delimiter ',' csv header;
\copy authorpaperlist from '/home/sanjeev/Desktop/airport_data/authors/authorpaperlist.csv' delimiter ',' csv header;
\copy citationlist from '/home/sanjeev/Desktop/airport_data/authors/citationlist.csv' delimiter ',' csv header;