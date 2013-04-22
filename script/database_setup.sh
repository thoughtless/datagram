#!/bin/bash

# bootstrap your local db.
cd db/
sqlite3 datagram_development.db "CREATE TABLE queries(content text, filter text);"
