# Toetle
A turtle testing API for when you have no turtles

# Why call it Toetle?
Stub functions -> stub toe -> toe turtle -> toetle

Even I get confused by my brain sometimes - @Lupus590

# What does it do?
A normal stub function would return nil which is not something that most turtle functions normally return. Toetle takes a list of responses from the programmer and returns those instead. Should the list be too short, toetle will give the first response again and continue down the list again.

This does *not* simulate a full turtle.

# Why make this?
Because HowlCI doesn't have a turtle API and Hive probably will need one.

# TODO and Notes Regarding Implementation
* alternative way of making it work: set value of to the handler function?
* what's the type of turtle.suck? what happens when it's printed?
* All toetle specific stuff should be in turtle.toetle where both turtle and toetle are tables. Other than the toetle subtable the turtle table should have the same keys/indexes as the vanilla turtle API.
* Functions in the turtle API returns an entry from their response list.
* Have a random mode? Entries in the list are returned randomly instead of in sequence?
* Try to have similar response time as vanilla turtle API? Put in sleeps?
* Responses are stored in a table, how to support nil responses?
 * 0 index of list is number of entries?
 * all entries are a sub table, response is in that table
 * what to do if no list was given? error seems best, if programmer wants nil then say so.
* Regarding functions to add responses:
 * Naming convention. Same as turtle API but in toetle table?
 * allow adding a table of responses? no, toetle is naive, it will return whatever you give it. If you want to add multiple responses then either manipulate the list directly or feed the responses one at a time to the input function (recommended)
* Interactive mode? Ask programmer for response each time.
 * specific functions only? IE can have only one or two functions query for input, rest can use lists.
* document handler functions
* fake world?
